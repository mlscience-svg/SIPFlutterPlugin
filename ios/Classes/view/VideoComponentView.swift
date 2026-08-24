import AVFoundation
import Flutter
import SIPFramework
import UIKit

class VideoComponentView: NSObject, FlutterPlatformView {
    static weak var currentInstance: VideoComponentView?
    private var _view: UIView
    var videoContainerView: UIView!
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
            let renderer = UIGraphicsImageRenderer(bounds: self._view.bounds)
            let image = renderer.image { _ in
                self._view.drawHierarchy(in: self._view.bounds, afterScreenUpdates: true)
            }
            completion(image.pngData())
        }
    }

    private func setupVideoView(view: UIView) {
        videoContainerView = UIView(frame: view.bounds)
        videoContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(videoContainerView)
    }

    func createNativeView(view _view: UIView) {
        videoContainerView = UIView(frame: _view.bounds)
        videoContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _view.addSubview(videoContainerView)
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

        videoLayer = layer
        DispatchQueue.main.async {
            layer.frame = self.videoContainerView.bounds
            self.videoContainerView.layer.addSublayer(layer)
            self.applyVideoGravity()
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
