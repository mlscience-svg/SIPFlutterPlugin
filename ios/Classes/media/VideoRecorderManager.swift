import AVFoundation
import UIKit

/// 通话录像：按目标帧率抓取视频视图（VideoComponentView）画面，逐帧写入
/// AVAssetWriter 合成 H.264 MP4。与拍照共用 drawHierarchy 机制，确保能
/// 捕获到 AVSampleBufferDisplayLayer 渲染的对方画面。
class VideoRecorderManager: NSObject {
    static let shared = VideoRecorderManager()

    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var displayLink: CADisplayLink?
    private weak var targetView: UIView?
    private var outputURL: URL?
    private var recording = false
    private var frameCount = 0
    private var sessionStartTime: CFTimeInterval = 0
    private var videoWidth = 640
    private var videoHeight = 480

    private let targetFPS: Double = 15

    var isRecording: Bool { recording }

    /// 开始录制，返回文件绝对路径；失败返回 nil。
    func startRecording(view: UIView, relativePath: String) -> String? {
        stopCapture()

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
        let path = url.path

        // 分辨率取视图实际尺寸（pt），兜底 640x480
        let bounds = view.bounds
        videoWidth = max(Int(bounds.width), 1)
        videoHeight = max(Int(bounds.height), 1)

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
            return nil
        }
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoWidth,
            AVVideoHeightKey: videoHeight,
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
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: videoWidth,
                kCVPixelBufferHeightKey as String: videoHeight,
            ])
        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        guard writer.startWriting() else { return nil }
        writer.startSession(atSourceTime: .zero)

        assetWriter = writer
        writerInput = input
        self.adaptor = adaptor
        targetView = view
        outputURL = url
        frameCount = 0
        sessionStartTime = 0
        recording = true

        let link = CADisplayLink(target: self, selector: #selector(frameTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        return path
    }

    /// 停止录制，回调返回文件绝对路径；无有效文件返回 nil。
    func stopRecording(completion: @escaping (String?) -> Void) {
        // 停止抓帧（CADisplayLink 必须主线程操作），再后台封存 MP4
        if Thread.isMainThread {
            stopCapture()
        } else {
            DispatchQueue.main.sync { stopCapture() }
        }

        let writer = assetWriter
        let input = writerInput
        let path = outputURL?.path

        DispatchQueue.global(qos: .userInitiated).async {
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
                self.cleanup()
                completion(finalPath)
            }
        }
    }

    private func stopCapture() {
        guard recording else { return }
        recording = false
        displayLink?.invalidate()
        displayLink = nil
        targetView = nil
    }

    private func cleanup() {
        assetWriter = nil
        writerInput = nil
        adaptor = nil
        outputURL = nil
        frameCount = 0
        sessionStartTime = 0
    }

    @objc private func frameTick(_ link: CADisplayLink) {
        guard recording, let writer = assetWriter, writer.status == .writing,
              let input = writerInput, input.isReadyForMoreMediaData,
              let view = targetView else { return }

        // 节流到目标帧率
        let now = link.timestamp
        if sessionStartTime == 0 { sessionStartTime = now }
        let expectedFrames = Int((now - sessionStartTime) * targetFPS)
        guard expectedFrames > frameCount else { return }
        frameCount = expectedFrames

        guard let pixelBuffer = makePixelBuffer(from: view) else { return }
        let pts = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(targetFPS))
        adaptor?.append(pixelBuffer, withPresentationTime: pts)
    }

    /// 把视图渲染进 BGRA 像素缓冲（与拍照一致的 drawHierarchy 方式）。
    /// 直接 CVPixelBufferCreate 自建缓冲：adaptor 的 pixelBufferPool 惰性创建，
    /// append 前取不到，不能依赖它。
    private func makePixelBuffer(from view: UIView) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            videoWidth, videoHeight,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer)
        guard let pixelBuffer else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        guard let cgImage = image.cgImage else { return pixelBuffer }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: videoWidth,
            height: videoHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return pixelBuffer
        }
        // CoreGraphics 与 UIKit 的 Y 轴相反，翻转后再绘制
        ctx.translateBy(x: 0, y: CGFloat(videoHeight))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: videoWidth, height: videoHeight))
        return pixelBuffer
    }
}
