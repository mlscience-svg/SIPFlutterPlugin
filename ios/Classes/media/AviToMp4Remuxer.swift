import Foundation

/// AVI（H.264 Annex-B 字节流，门铃录像格式）→ MP4（H.264，avc1/avcC）无损重封装。
///
/// iOS 的 AVPlayer 无法解析 AVI 容器，拉取到的门铃 .AVI 需先重封装成 MP4 才能播放。
/// 做法：解析 AVI 的 RIFF 结构，定位 hdrl 里视频流的 strh/strf（帧率、宽高）与
/// movi 里每个 '00dc' 视频帧；把帧内以起始码分隔的 NAL 整理成 AVCC 样本（4 字节
/// 长度前缀），SPS/PPS 抽进 avcC 解码器配置并从样本中去掉（avc1 不允许带内参数集，
/// 后续 IDR 靠 avcC 的参数集即可解）。v1 仅视频轨，丢弃门铃的 PCM 音频轨。
/// 纯 Foundation 实现，可同时用于 iOS 插件内与 macOS 命令行工具验证。
public enum AviToMp4Remuxer {
    public struct Stats {
        public let width: Int
        public let height: Int
        public let frameCount: Int
        public let durationMs: Int
    }

    public enum RemuxError: Swift.Error, CustomStringConvertible {
        case msg(String)
        public var description: String {
            if case .msg(let s) = self { return s }
            return "unknown"
        }
    }

    /// 输出 MP4 统一用 90000 时间基，30fps 每帧 3000。
    private static let timescale: UInt32 = 90000

    public static func remux(from aviURL: URL, to mp4URL: URL) throws -> Stats {
        let d: Data
        do { d = try Data(contentsOf: aviURL) } catch { throw RemuxError.msg("read avi failed: \(error)") }
        let n = d.count
        guard n > 12, d[0] == 0x52, d[1] == 0x49, d[2] == 0x46, d[3] == 0x46 else {
            throw RemuxError.msg("not a RIFF/AVI file")
        }

        // ---- LE 读取（AVI 字段） ----
        func le32(_ o: Int) -> UInt32 {
            UInt32(d[o]) | UInt32(d[o + 1]) << 8 | UInt32(d[o + 2]) << 16 | UInt32(d[o + 3]) << 24
        }
        func lei32(_ o: Int) -> Int32 { Int32(bitPattern: le32(o)) }
        func tag(_ o: Int, _ s: String) -> Bool {
            guard o + 4 <= n else { return false }
            var i = 0
            for ch in s.utf8 { if d[o + i] != ch { return false }; i += 1 }
            return true
        }

        // ---- 顶层 RIFF 解析：找 hdrl（视频 strh/strf）+ movi 范围 ----
        var vidRate = 0, vidScale = 0, vidW = 0, vidH = 0
        var moviStart = -1, moviEnd = -1
        var pos = 12
        while pos + 8 <= n {
            let sz = Int(le32(pos + 4))
            let contentEnd = min(pos + 8 + sz, n)
            if tag(pos, "LIST") {
                if tag(pos + 8, "movi") {
                    moviStart = pos + 12
                    moviEnd = contentEnd
                } else if tag(pos + 8, "hdrl") {
                    // 遍历 hdrl 子块（偶数对齐），找到 vids 的 strl
                    var q = pos + 12
                    while q + 8 <= contentEnd {
                        let s2 = Int(le32(q + 4))
                        let ce2 = min(q + 8 + s2, contentEnd)
                        if tag(q, "LIST") && tag(q + 8, "strl") {
                            var want = false
                            var r = q + 12
                            while r + 8 <= ce2 {
                                let s3 = Int(le32(r + 4))
                                if tag(r, "strh") {
                                    want = tag(r + 8, "vids")
                                    if want {
                                        vidRate = Int(le32(r + 8 + 24))
                                        vidScale = Int(le32(r + 8 + 20))
                                    }
                                } else if tag(r, "strf"), want, vidW == 0 {
                                    vidW = abs(Int(lei32(r + 8 + 4)))
                                    vidH = abs(Int(lei32(r + 8 + 8)))
                                }
                                r += 8 + s3 + (s3 & 1)
                            }
                        }
                        q += 8 + s2 + (s2 & 1)
                    }
                }
            } else if tag(pos, "movi") {
                // 有的 AVI 把 movi 写成顶层 RIFF chunk（非 LIST movi）也要认。
                moviStart = pos + 8
                moviEnd = contentEnd
            }
            pos += 8 + sz + (sz & 1)
        }
        guard moviStart >= 0, moviStart < moviEnd else {
            throw RemuxError.msg("no movi list found")
        }

        // ---- 把一段 NAL 字节流切成一串 NAL（返回绝对偏移 + 长度 + 类型） ----
        func nalRegions(_ base: Int, _ len: Int) -> [(start: Int, len: Int, type: Int)] {
            let end = base + len
            var out: [(Int, Int, Int)] = []
            var search = base
            while true {
                var k = search
                while k + 3 <= end {
                    if d[k] == 0 && d[k + 1] == 0 && d[k + 2] == 1 { break }
                    k += 1
                }
                if k + 3 > end { break }
                let payloadStart = k + 3
                var k2 = payloadStart
                while k2 + 3 <= end {
                    if d[k2] == 0 && d[k2 + 1] == 0 && d[k2 + 2] == 1 { break }
                    k2 += 1
                }
                let payloadEnd: Int
                if k2 + 3 <= end {
                    payloadEnd = k2
                    // 下个迭代从 k2 重新命中该起始码，登记紧邻的下一 NAL；
                    // 若设成 k2+3 会跳过每第 2 个起始码，PPS 等紧邻 NAL 会丢失。
                    search = k2
                } else {
                    payloadEnd = end
                    search = end
                }
                if payloadEnd > payloadStart {
                    out.append((payloadStart, payloadEnd - payloadStart, Int(d[payloadStart] & 0x1f)))
                }
                if payloadEnd == end { break }
            }
            return out
        }

        // ---- 遍历 movi 子块（无偶数对齐！实测该设备 movi 内不 padding），收 '00dc' ----
        var sps: Data? = nil
        var pps: Data? = nil
        var nalLists: [[(start: Int, len: Int)]] = []   // 每个视频帧保留的 NAL
        var sampleSizes: [UInt32] = []
        var syncIndexes: [UInt32] = []
        var totalBytes: UInt64 = 0
        var o = moviStart
        while o + 8 <= moviEnd {
            let sz = Int(le32(o + 4))
            let cs = o + 8
            if cs + sz > moviEnd { break }
            if tag(o, "00dc") {
                let regs = nalRegions(cs, sz)
                var kept: [(Int, Int)] = []
                var sampleSize: UInt32 = 0
                var sync = false
                for r in regs {
                    let t = r.type
                    if t == 7, sps == nil { sps = d[r.start..<(r.start + r.len)] }
                    else if t == 8, pps == nil { pps = d[r.start..<(r.start + r.len)] }
                    if t == 7 || t == 8 || t == 9 { continue } // 去 SPS/PPS/AUD
                    if t == 5 { sync = true }
                    kept.append((r.start, r.len))
                    sampleSize += UInt32(4 + r.len)
                }
                if kept.isEmpty {
                    throw RemuxError.msg("video frame has no slice data")
                }
                nalLists.append(kept)
                sampleSizes.append(sampleSize)
                totalBytes += UInt64(sampleSize)
                if sync { syncIndexes.append(UInt32(sampleSizes.count)) }
            }
            // 实测样本 movi 子块无 padding（帧头落在奇地址）；但部分门铃固件按 2 字节
            // 对齐补 0。容错：若紧随本块的是单个 0x00 且跳过后是合法 chunk（size 落在
            // movi 内），视为 padding 跳 1 字节，否则按紧邻处理。
            var nxt = cs + sz
            if nxt < moviEnd, d[nxt] == 0, nxt + 1 + 8 <= moviEnd {
                let s2 = Int(le32(nxt + 1 + 4))
                if nxt + 1 + 8 + s2 <= moviEnd { nxt += 1 }
            }
            o = nxt
        }
        guard !nalLists.isEmpty else { throw RemuxError.msg("no video frames (00dc) in movi") }
        guard let sps, let pps else { throw RemuxError.msg("SPS/PPS not found in video frames") }
        guard vidW > 0, vidH > 0 else { throw RemuxError.msg("invalid video dimensions") }
        guard totalBytes <= 0xFFFFFFE0 else { throw RemuxError.msg("video too large for 32-bit mdat") }

        // 帧率 → mdhd/mvhd 每帧时长
        let frameDur: UInt32
        if vidRate > 0, vidScale > 0 {
            frameDur = UInt32((UInt64(timescale) * UInt64(vidScale)) / UInt64(vidRate))
        } else {
            frameDur = timescale / 30
        }
        let frameCount = UInt32(nalLists.count)
        let duration = frameCount * frameDur

        // ================= 组装 MP4 =================
        // BE 写
        func be32(_ v: UInt32) -> [UInt8] {
            [UInt8(v >> 24 & 0xFF), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)]
        }
        func be16(_ v: UInt16) -> [UInt8] { [UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)] }


        // --- ftyp ---
        let ftypBox: Data = {
            var c = Data()
            c.append("isom".data(using: .utf8)!)
            c.append(contentsOf: be32(0x200))
            for b in ["isom", "iso2", "avc1", "mp41"] { c.append(b.data(using: .utf8)!) }
            var bx = Data()
            bx.append(contentsOf: be32(UInt32(8 + c.count)))
            bx.append("ftyp".data(using: .utf8)!)
            bx.append(c)
            return bx
        }()

        // --- moov 的静态部分 ---
        func fullbox(_ flags: UInt32) -> Data { Data(be32(flags)) } // version0

        func mvhdBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(0)); c.append(contentsOf: be32(0)) // create/mod
            c.append(contentsOf: be32(timescale))
            c.append(contentsOf: be32(duration))
            c.append(contentsOf: be32(0x00010000)) // rate
            c.append(contentsOf: be16(0x0100))     // volume
            c.append(contentsOf: be16(0))          // reserved
            c.append(contentsOf: Data(count: 8))   // reserved x2
            for m in [0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000] {
                c.append(contentsOf: be32(UInt32(m)))
            }
            c.append(contentsOf: Data(count: 24))  // pre_defined
            c.append(contentsOf: be32(2))          // next_track_ID
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("mvhd".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func tkhdBox() -> Data {
            var c = fullbox(0x000003) // enabled | in_movie
            c.append(contentsOf: be32(0)); c.append(contentsOf: be32(0))
            c.append(contentsOf: be32(1))              // track_ID
            c.append(contentsOf: be32(0))              // reserved
            c.append(contentsOf: be32(duration))
            c.append(contentsOf: Data(count: 8))
            c.append(contentsOf: be16(0)); c.append(contentsOf: be16(0))
            c.append(contentsOf: be16(0x0100)); c.append(contentsOf: be16(0))
            for m in [0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000] {
                c.append(contentsOf: be32(UInt32(m)))
            }
            c.append(contentsOf: be32(UInt32(vidW << 16)))  // width in 16.16
            c.append(contentsOf: be32(UInt32(vidH << 16)))
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("tkhd".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func mdhdBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(0)); c.append(contentsOf: be32(0))
            c.append(contentsOf: be32(timescale))
            c.append(contentsOf: be32(duration))
            c.append(contentsOf: be16(0x55C4)) // 'und' language
            c.append(contentsOf: be16(0))
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("mdhd".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func hdlrBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(0))
            c.append("vide".data(using: .utf8)!)
            c.append(contentsOf: Data(count: 12))
            c.append("VideoHandler".data(using: .utf8)!)
            c.append(0)
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("hdlr".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func vmhdBox() -> Data {
            var c = fullbox(1)
            c.append(contentsOf: be16(0))   // graphics mode
            c.append(contentsOf: Data(count: 6)) // opcolor
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("vmhd".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func drefBox() -> Data {
            let urlC = Data(be32(0x00000001)) // self-contained url fullbox
            var urlBox = Data(be32(12)); urlBox.append("url ".data(using: .utf8)!); urlBox.append(urlC)
            var c = fullbox(0)
            c.append(contentsOf: be32(1))
            c.append(urlBox)
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("dref".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func avcCBox() -> Data {
            var c = Data()
            c.append(1)                                    // configurationVersion
            c.append(sps[sps.startIndex + 1])              // profile_idc
            c.append(sps[sps.startIndex + 2])              // profile_compat
            c.append(sps[sps.startIndex + 3])              // level_idc
            c.append(0xFF)                                 // lengthSizeMinusOne=3
            c.append(0xE1)                                 // 1 SPS
            c.append(contentsOf: be16(UInt16(sps.count)))
            c.append(sps)
            c.append(1)                                    // 1 PPS
            c.append(contentsOf: be16(UInt16(pps.count)))
            c.append(pps)
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("avcC".data(using: .utf8)!); bx.append(c)
            return bx
        }

        // avc1 VisualSampleEntry（含 avcC 子盒）
        func avc1Box() -> Data {
            var c = Data(count: 6)                 // reserved
            c.append(contentsOf: be16(1))          // data_reference_index
            c.append(contentsOf: be16(0))          // pre_defined
            c.append(contentsOf: be16(0))          // reserved
            c.append(contentsOf: Data(count: 12))  // pre_defined x3
            c.append(contentsOf: be16(UInt16(vidW)))
            c.append(contentsOf: be16(UInt16(vidH)))
            c.append(contentsOf: be32(0x00480000)) // horiz
            c.append(contentsOf: be32(0x00480000)) // vert
            c.append(contentsOf: be32(0))          // reserved
            c.append(contentsOf: be16(1))          // frame_count
            c.append(contentsOf: Data(count: 32))  // compressorname
            c.append(contentsOf: be16(24))         // depth
            c.append(contentsOf: be16(0xFFFF))     // pre_defined
            c.append(avcCBox())
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("avc1".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func stsdBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(1))
            c.append(avc1Box())
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("stsd".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func sttsBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(1))
            c.append(contentsOf: be32(frameCount))
            c.append(contentsOf: be32(frameDur))
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("stts".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func stscBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(1))          // 1 个 chunk 装全部样本
            c.append(contentsOf: be32(1))          // first_chunk
            c.append(contentsOf: be32(frameCount)) // samples_per_chunk
            c.append(contentsOf: be32(1))          // sample_description_index
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("stsc".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func stszBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(0)) // sample_size=0 → 逐个列
            c.append(contentsOf: be32(frameCount))
            for s in sampleSizes { c.append(contentsOf: be32(s)) }
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("stsz".data(using: .utf8)!); bx.append(c)
            return bx
        }

        // 单一 chunk：chunk 偏移 = mdat 内容起始绝对偏移（ftyp + mdat 头）
        let mdatContentOffset = UInt32(ftypBox.count + 8)
        func stcoBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(1))
            c.append(contentsOf: be32(mdatContentOffset))
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("stco".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func stssBox() -> Data {
            var c = fullbox(0)
            c.append(contentsOf: be32(UInt32(syncIndexes.count)))
            for s in syncIndexes { c.append(contentsOf: be32(s)) }
            var bx = Data(be32(UInt32(8 + c.count)))
            bx.append("stss".data(using: .utf8)!); bx.append(c)
            return bx
        }

        func box(_ type: String, _ content: Data) -> Data {
            var b = Data(be32(UInt32(8 + content.count)))
            b.append(type.data(using: .utf8)!); b.append(content)
            return b
        }

        func moovBox() -> Data {
            var moov = Data()
            moov.append(mvhdBox())
            // trak
            var mdia = Data()
            mdia.append(mdhdBox())
            mdia.append(hdlrBox())
            var minf = Data()
            minf.append(vmhdBox())
            // minf 必须按 ISO 分层：vmhd / dinf{ dref } / stbl{ stsd.. }。
            // 曾漏包 dinf、stbl 这两个容器头，把子 box 平铺进 minf；ffmpeg 宽容能扫出
            // 样本表，AVPlayer/CoreMedia 严格解析直接丢轨（videoTracks=0）。
            minf.append(box("dinf", drefBox()))
            var stbl = Data()
            stbl.append(stsdBox())
            stbl.append(sttsBox())
            stbl.append(stscBox())
            stbl.append(stszBox())
            stbl.append(stcoBox())
            if !syncIndexes.isEmpty { stbl.append(stssBox()) }
            minf.append(box("stbl", stbl))
            mdia.append(box("minf", minf))
            var trak = Data()
            trak.append(tkhdBox())
            trak.append(box("mdia", mdia))
            moov.append(box("trak", trak))
            return box("moov", moov)
        }

        // ================= 写文件 =================
        do {
            try FileManager.default.createDirectory(
                at: mp4URL.deletingLastPathComponent(),
                withIntermediateDirectories: true, attributes: nil)
        } catch {}
        // 整块 Data 组装后一次性写盘：FileHandle.write(contentsOf:) 要 iOS 13.4+，
        // 插件 deployment 是 13.0；Data.write(to:options:) 全版本可用，且省去逐次写。
        var out = Data()
        out.append(ftypBox)

        // mdat 头
        var mdatHeader = Data()
        mdatHeader.append(contentsOf: be32(UInt32(8 + totalBytes)))
        mdatHeader.append("mdat".data(using: .utf8)!)
        out.append(mdatHeader)

        // 逐样本写（长度前缀 + NAL）
        for frame in nalLists {
            for r in frame {
                out.append(contentsOf: be32(UInt32(r.len)))
                out.append(d[r.start..<(r.start + r.len)])
            }
        }
        out.append(moovBox())

        do {
            try out.write(to: mp4URL, options: [.atomic])
        } catch {
            throw RemuxError.msg("write mp4 failed: \(error)")
        }

        return Stats(width: vidW, height: vidH,
                     frameCount: Int(frameCount),
                     durationMs: Int(UInt64(duration) * 1000 / UInt64(timescale)))
    }
}
