import AVFoundation
import Flutter
import SIPFramework
import UIKit

class VideoComponentView: NSObject, FlutterPlatformView {
    private var _view: UIView
    var videoContainerView: UIView!
    private var videoLayer: AVSampleBufferDisplayLayer?

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
            layer.videoGravity = .resizeAspect
            self.videoContainerView.layer.addSublayer(layer)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
