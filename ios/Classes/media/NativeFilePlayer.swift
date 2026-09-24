import AVFoundation
import Flutter
import QuartzCore
import UIKit

/// 本地文件视频（MP4）→ FlutterTexture 的内嵌播放器。
///
/// createVideoPlayer 等 channel 方法由本类支撑，语义与 Android 的 MediaPlayer +
/// TextureRegistry 方案对齐：
///  - AVPlayer 播本地 MP4，AVPlayerItemVideoOutput 逐帧取出 BGRA 像素；
///  - 一个 CADisplayLink 在播放/暂停/seek 时把最新帧送进 Flutter 纹理
///    （copyPixelBuffer），并用 textureFrameAvailable 通知引擎重绘 —— 引擎纹理
///    管线的拉取模式，不会出现黑图。
///  - 门铃录像原始是 AVI，AVPlayer 解不了；调用方（SipSdkFlutterPlugin）会先把
///    .AVI 用 AviToMp4Remuxer 重封装成临时 MP4 再交给本类播放。iOS 需在暂停时
///    仍能显示当前帧，所以 displayLink 常驻，暂停时仅在帧变化时通知一次。
public final class NativeFilePlayer: NSObject, FlutterTexture {
    /// 引擎纹理 id：init 里调用 registry.register(self)（需要 self 完整，
    /// 只能放 super.init() 之后）后回填，故为带默认值的 var。
    public private(set) var textureId: Int64 = 0
    public let fileURL: URL
    /// dispose 时是否删除 fileURL（true = 本次 create 重封装出的临时 MP4）。
    private let deleteOnClose: Bool

    private let registry: FlutterTextureRegistry
    private let playerItem: AVPlayerItem
    private let player = AVPlayer()
    private let videoOutput: AVPlayerItemVideoOutput

    private var displayLink: CADisplayLink?
    private let lock = NSLock()
    private var latestBuffer: CVPixelBuffer?
    private var disposed = false

    /// 创建播放器并注册到纹理管线。文件需已是可被 AVPlayer 播放的本地媒体
    /// （MP4 等）。失败返回 nil（不产生纹理 id）。
    init?(fileURL: URL, deleteOnClose: Bool, registry: FlutterTextureRegistry) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            NSLog("[SIPSDK] NativeFilePlayer init nil: file missing %@",
                  fileURL.path)
            return nil
        }
        self.fileURL = fileURL
        self.deleteOnClose = deleteOnClose
        self.registry = registry

        // BGRA + IOSurface/Metal 兼容：Flutter 引擎纹理要求 IOSurface 背衬，
        // 这样引擎能直接经 Metal 呈现，不额外拷贝。
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferMetalCompatibilityKey as String: true,
        ]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: attrs)
        let item = AVPlayerItem(asset: AVURLAsset(url: fileURL))
        item.add(output)

        self.videoOutput = output
        self.playerItem = item
        super.init()

        player.actionAtItemEnd = .pause
        player.replaceCurrentItem(with: item)

        let tid = registry.register(self)
        guard tid != 0 else {
            NSLog("[SIPSDK] NativeFilePlayer init nil: registerTexture returned 0")
            return nil
        }
        textureId = tid
        NSLog("[SIPSDK] NativeFilePlayer init ok textureId=%lld %@",
              textureId, fileURL.path)
    }

    /// 开始播放：常驻 displayLink + 自动开播（onPrepared 自动 start 语义与
    /// Android 一致；Dart 侧首次轮询到 duration 后会自己暂停等用户点播放）。
    func start() {
        guard !disposed else { return }
        startDisplayLink()
        player.play()
    }

    func play() {
        guard !disposed else { return }
        player.play()
    }

    func pause() {
        guard !disposed else { return }
        player.pause()
    }

    func seek(toMilliseconds ms: Int) {
        guard !disposed else { return }
        let t = CMTime(seconds: Double(ms) / 1000.0, preferredTimescale: 1000)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// 播放状态：{position, duration, playing, videoWidth, videoHeight, error?}，
    /// 与 Android videoPlayerState 返回一致。
    func state() -> [String: Any] {
        guard !disposed else {
            return ["position": 0, "duration": 0, "playing": false]
        }
        var s: [String: Any] = [:]
        let posSeconds = playerItem.currentTime().seconds
        s["position"] = posSeconds.isFinite ? Int((posSeconds * 1000).rounded()) : 0

        var durMs = 0
        let dur = playerItem.duration
        if dur.isNumeric, dur.seconds.isFinite {
            durMs = Int((dur.seconds * 1000).rounded())
        } else {
            // item 未 ready 时 duration 可能为 indefinite；asset 往往已带时长
            let ad = playerItem.asset.duration
            if ad.isNumeric, ad.seconds.isFinite {
                durMs = Int((ad.seconds * 1000).rounded())
            }
        }
        s["duration"] = durMs
        s["playing"] = player.timeControlStatus == .playing

        let size = playerItem.presentationSize
        if size.width > 0, size.height > 0 {
            s["videoWidth"] = Int(size.width)
            s["videoHeight"] = Int(size.height)
        }
        if let err = playerItem.error?.localizedDescription, !err.isEmpty {
            s["error"] = err
        }
        return s
    }

    /// 释放播放器、纹理与临时文件（幂等）。
    func dispose() {
        guard !disposed else { return }
        disposed = true
        stopDisplayLink()
        player.pause()
        player.cancelPendingPrerolls()
        playerItem.cancelPendingSeeks()
        player.replaceCurrentItem(with: nil)
        registry.unregisterTexture(textureId)
        lock.lock()
        latestBuffer = nil
        lock.unlock()
        if deleteOnClose {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    deinit {
        stopDisplayLink()
    }

    // MARK: - FlutterTexture

    /// 引擎请求当前帧像素：直接返回最近一帧 BGRA 缓冲（displayLink 已在主线程
    /// 放好最新帧）。FlutterTexture 契约是「返回 retained、引擎用后 CFRelease」
    /// （同官方 camera_avfoundation：引擎拿到 +1）。所以每次拉帧都要给引擎补一份
    /// +1（passUnretained().retain()），我们仍持有 latestBuffer 供暂停后重绘取帧；
    /// 若只传 +0（passUnretained），引擎照常 release 会白扣引用，把仍被
    /// AVPlayerItemVideoOutput 引用的 IOSurface 提前 free，随后释放即崩（CFRelease
    /// PAC fail / double free）。
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        lock.lock()
        defer { lock.unlock() }
        guard let b = latestBuffer else { return nil }
        return Unmanaged.passUnretained(b).retain()
    }

    // MARK: - 帧驱动

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(displayTick(_:)))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayTick(_: CADisplayLink) {
        guard !disposed else { return }
        let itemTime = playerItem.currentTime()
        guard itemTime.isValid, itemTime.isNumeric,
              let buf = videoOutput.copyPixelBuffer(
                  forItemTime: itemTime, itemTimeForDisplay: nil) else {
            return
        }
        // 播放中每帧都推；暂停时仅在帧变化（首帧/seek 落点）时推一次，避免无谓重绘。
        var changed = false
        lock.lock()
        if latestBuffer !== buf {
            latestBuffer = buf
            changed = true
        }
        lock.unlock()
        if changed || player.timeControlStatus == .playing {
            registry.textureFrameAvailable(textureId)
        }
    }
}
