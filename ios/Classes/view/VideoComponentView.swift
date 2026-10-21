import AVFoundation
import CoreImage
import Flutter
import SIPFramework
import UIKit

/// 视频容器：AVSampleBufferDisplayLayer 是手动 addSublayer 加进来的，不会跟随
/// UIView 的 autoresizingMask 变化；全屏/旋屏后平台视图尺寸变了，画面却还停在
/// 旧尺寸的左上角，看起来就是黑的。在 layoutSubviews 里同步子图层 frame。
private final class VideoContainerView: UIView {
    weak var displayLayer: AVSampleBufferDisplayLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let displayLayer = displayLayer,
              displayLayer.superlayer === layer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.frame = bounds
        CATransaction.commit()
    }
}

class VideoComponentView: NSObject, FlutterPlatformView {
    static weak var currentInstance: VideoComponentView?

    /// 当前通话的视频图层。由 SIPFramework 创建，只在 VIDEO_LAYER_READY 通知里
    /// 交付一次；而 Flutter 侧布局变化（例如全屏切换）可能销毁重建平台视图，
    /// 新实例收不到第二次通知。这里强引用住最新图层，新实例直接接回去，
    /// 否则重建后永远是黑屏。
    private static var currentVideoLayer: AVSampleBufferDisplayLayer?

    private var _view: UIView
    private var videoContainerView: VideoContainerView!
    private var videoLayer: AVSampleBufferDisplayLayer?
    // 图像比例：true=1:1 按实际比例(留黑边)，false=铺满(拉伸变形)。默认 1:1。
    private var isOriginalRatio = true

    // flutter侧传入参数
    private var arguments: Any?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments args: Any?,
        binaryMessenger _: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        VideoComponentView.currentInstance = self
        _view.backgroundColor = UIColor.black
        arguments = args
        createNativeView(view: _view)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cameraStateChangeReady(_:)),
            name: .CAMERA_STATE_CHANGE,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVideoLayerReady(_:)),
            name: .VIDEO_LAYER_READY,
            object: nil
        )
    }

    func view() -> UIView {
        _view
    }

    func captureSnapshot(completion: @escaping (Data?) -> Void) {
        DispatchQueue.main.async {
            // 远端画面由 AVSampleBufferDisplayLayer 硬件呈现，drawHierarchy 截出来是黑的；
            // 改用 SDK 并行硬解出的真实解码帧。
            guard let buffer = RemoteVideoFrameCenter.shared.latestPixelBuffer,
                  let image = Self.makeImage(from: buffer) else {
                completion(nil)
                return
            }
            completion(image.pngData())
        }
    }

    private static let imageContext = CIContext()

    private static func makeImage(from buffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = imageContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func setupVideoView(view: UIView) {
        videoContainerView = VideoContainerView(frame: view.bounds)
        videoContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(videoContainerView)
        attachCurrentLayerIfNeeded()
    }

    func createNativeView(view _view: UIView) {
        videoContainerView = VideoContainerView(frame: _view.bounds)
        videoContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _view.addSubview(videoContainerView)
        attachCurrentLayerIfNeeded()
    }

    /// 平台视图重建时把已经存在的视频图层接回来。
    private func attachCurrentLayerIfNeeded() {
        guard let layer = VideoComponentView.currentVideoLayer else { return }
        attach(layer)
    }

    /// 把视频图层挂到当前容器上。图层可能还挂在旧的（已销毁的）容器上，
    /// 先摘下来再挂，避免同一图层出现在两处。
    private func attach(_ layer: AVSampleBufferDisplayLayer) {
        videoLayer = layer
        videoContainerView.displayLayer = layer
        layer.removeFromSuperlayer()
        layer.frame = videoContainerView.bounds
        videoContainerView.layer.addSublayer(layer)
        videoContainerView.setNeedsLayout()
        applyVideoGravity()
    }

    @objc private func cameraStateChangeReady(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let isRunning = userInfo["isRunning"] as? Bool else { return }
        DispatchQueue.main.async {
            let payload: [String: Any] = [
                "state": isRunning,
            ]
            SipSdkFlutterPlugin.channel?.invokeMethod("onCameraStateChange", arguments: payload)
        }
    }

    @objc private func handleVideoLayerReady(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let layer = userInfo["layer"] as? AVSampleBufferDisplayLayer else { return }

        VideoComponentView.currentVideoLayer = layer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.attach(layer)
        }
    }

    func setImageRatio(originalRatio: Bool) {
        isOriginalRatio = originalRatio
        DispatchQueue.main.async {
            self.applyVideoGravity()
        }
    }

    /// 清空视频表面（只留纯黑底色），用于挂断/切换通道时清掉上一通道的残留画面。
    func clearVideo() {
        DispatchQueue.main.async {
            self.videoLayer?.flushAndRemoveImage()
        }
    }

    private func applyVideoGravity() {
        videoLayer?.videoGravity = isOriginalRatio ? .resizeAspect : .resize
    }

    deinit {
        if VideoComponentView.currentInstance === self {
            VideoComponentView.currentInstance = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
}
