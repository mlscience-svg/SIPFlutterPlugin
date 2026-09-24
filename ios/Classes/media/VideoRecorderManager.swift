import AVFoundation
import QuartzCore
import SIPFramework
import UIKit

/// 通话录像：把 SDK 硬解出的真实解码帧（RemoteVideoFrameCenter）按目标帧率逐帧写入
/// AVAssetWriter 合成 H.264 MP4。
///
/// 不抓屏幕：远端画面由 AVSampleBufferDisplayLayer 硬件呈现，UIKit 抓屏截不到
/// （drawHierarchy 结果是黑的），只能消费解码器输出的 CVPixelBuffer。
class VideoRecorderManager: NSObject {
    static let shared = VideoRecorderManager()

    /// 串行化 writer 生命周期与写帧，避免与解码回调线程竞争
    private let queue = DispatchQueue(label: "com.sip.videoRecorder.queue")
    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private var recording = false
    private var frameCount = 0
    private var lastAppendHostTime: CFTimeInterval = 0

    private let targetFPS: Double = 15
    private let minFrameInterval: CFTimeInterval

    override init() {
        minFrameInterval = 1.0 / 15
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onRemoteFrame(_:)),
            name: .REMOTE_VIDEO_FRAME_READY,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var isRecording: Bool {
        queue.sync { recording }
    }

    @objc private func onRemoteFrame(_ notification: Notification) {
        queue.async { [weak self] in
            self?.consumeLatestFrame()
        }
    }

    /// 开始录制，返回文件绝对路径；失败返回 nil。
    /// view 参数保留兼容调用方，录制已不再依赖视图内容。
    func startRecording(view: UIView, relativePath: String) -> String? {
        queue.sync {
            stopCaptureLocked()
            // 若上一段没停干净还留着惰性 writer，先丢弃，确保新 URL 重新按尺寸创建
            assetWriter = nil
            writerInput = nil
            adaptor = nil

            let docs = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true).first ?? ""
            let url = URL(fileURLWithPath: (docs as NSString).appendingPathComponent(relativePath))
            do {
                try FileManager.default.createDirectory(
                    atPath: url.deletingLastPathComponent().path,
                    withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }

            outputURL = url
            recording = true
            frameCount = 0
            lastAppendHostTime = 0
            return url.path
        }
    }

    /// 停止录制，回调返回文件绝对路径；无有效文件返回 nil。
    func stopRecording(completion: @escaping (String?) -> Void) {
        queue.async {
            self.stopCaptureLocked()
            let writer = self.assetWriter
            let input = self.writerInput
            let path = self.outputURL?.path
            self.assetWriter = nil
            self.writerInput = nil
            self.adaptor = nil
            self.outputURL = nil

            // 等编码器写完已接收的帧
            if let writer, let input {
                let semaphore = DispatchSemaphore(value: 0)
                input.markAsFinished()
                writer.finishWriting {
                    semaphore.signal()
                }
                _ = semaphore.wait(timeout: .now() + 3)
            }

            var finalPath: String?
            if let path {
                let fm = FileManager.default
                if let size = (try? fm.attributesOfItem(atPath: path))?[.size] as? Int,
                   size > 0 {
                    finalPath = path
                } else {
                    try? fm.removeItem(atPath: path)
                }
            }
            DispatchQueue.main.async {
                completion(finalPath)
            }
        }
    }

    private func stopCaptureLocked() {
        recording = false
    }

    /// 解码回调触发：若正在录制且还没到上一帧的节流间隔，则把最新解码帧写进 MP4。
    private func consumeLatestFrame() {
        guard recording else { return }
        guard let buffer = RemoteVideoFrameCenter.shared.latestPixelBuffer else { return }

        // 首个帧到达时才真正建 writer，分辨率按实际解码尺寸
        if assetWriter == nil, !setupWriter(with: buffer) {
            return
        }

        let now = CACurrentMediaTime()
        if lastAppendHostTime == 0 {
            lastAppendHostTime = now
            return
        }
        guard now - lastAppendHostTime >= minFrameInterval else { return }
        lastAppendHostTime = now

        frameCount += 1
        let pts = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(targetFPS))
        adaptor?.append(buffer, withPresentationTime: pts)
    }

    private func setupWriter(with buffer: CVPixelBuffer) -> Bool {
        guard let url = outputURL else { return false }
        let width = Int(CVPixelBufferGetWidth(buffer))
        let height = Int(CVPixelBufferGetHeight(buffer))
        guard width > 0, height > 0 else { return false }

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
            return false
        }
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1_200_000,
                AVVideoExpectedSourceFrameRateKey: targetFPS,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
            ],
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                // 与 SDK 并行硬解输出的 NV12 保持一致（见 H264Decoder.createVideoToolboxSession）
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ])
        guard writer.canAdd(input) else { return false }
        writer.add(input)
        guard writer.startWriting() else { return false }
        writer.startSession(atSourceTime: .zero)

        assetWriter = writer
        writerInput = input
        self.adaptor = adaptor
        return true
    }
}
