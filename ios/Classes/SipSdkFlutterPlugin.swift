import Flutter
import SIPFramework
import UIKit
import AVFoundation
import AVKit
import ImageIO
import Photos

public class SipSdkFlutterPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?

    /// 内嵌文件视频播放（createVideoPlayer 等 channel 方法）：textureId -> 播放器。
    /// Android 用 TextureRegistry + MediaPlayer；iOS 用 FlutterTexture + AVPlayer。
    private var textureRegistry: FlutterTextureRegistry?
    private var nativePlayers: [Int64: NativeFilePlayer] = [:]

    /// 最近一次 createVideoPlayer 失败的原因：Dart 侧拿到 null 后用
    /// videoPlayerLastError 查询，便于真机定位（成功时为 nil）。
    private var lastVideoPlayerError: String?

    /// 打印当前加载的 SIPFramework 版本,用于确认打包的 SDK 是否已更新
    private func printSIPFrameworkVersion() {
        let fw = Bundle(identifier: "com.sip.SIPFramework")
        let ver = fw?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = fw?.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        print("🔧 [SIPSDK] SIPFramework loaded version: \(ver) (build \(build))")
    }

    private func uint32Value(_ value: Any?, default defaultValue: UInt32 = 0) -> UInt32 {
        if let value = value as? UInt32 {
            return value
        }
        if let value = value as? Int {
            return UInt32(value)
        }
        if let value = value as? NSNumber {
            return value.uint32Value
        }
        if let value = value as? String, let parsed = UInt32(value) {
            return parsed
        }
        return defaultValue
    }

    private func uint64Value(_ value: Any?, default defaultValue: UInt64 = 0) -> UInt64 {
        if let value = value as? UInt64 {
            return value
        }
        if let value = value as? Int {
            return UInt64(value)
        }
        if let value = value as? NSNumber {
            return value.uint64Value
        }
        if let value = value as? String, let parsed = UInt64(value) {
            return parsed
        }
        return defaultValue
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sip_sdk_flutter", binaryMessenger: registrar.messenger())
        let instance = SipSdkFlutterPlugin()
        instance.textureRegistry = registrar.textures()
        SipSdkFlutterPlugin.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        // 注册视频界面
        let factory = VideoComponentFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.sip.flutter/VideoComponentView")
    }

    /// 引擎拆解时释放所有内嵌播放器（纹理与临时 MP4）。
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        for p in nativePlayers.values { p.dispose() }
        nativePlayers.removeAll()
        textureRegistry = nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initSDK":
            if let args = call.arguments as? [String: Any] {
                initSDK(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "initToken":
            if let args = call.arguments as? [String: Any] {
                initToken(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "localAccount":
            if let args = call.arguments as? [String: Any] {
                localAccount(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "remoteAccount":
            if let args = call.arguments as? [String: Any] {
                remoteAccount(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "delRemoteAccount":
            delRemoteAccount(args: [:], result: result)
        case "cameraOpen":
            if let args = call.arguments as? [String: Any] {
                cameraOpen(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "cameraClose":
            cameraClose(args: [:], result: result)
        case "captureSnapshot":
            captureSnapshot(args: [:], result: result)
        case "saveSnapshotToDocuments":
            let args = call.arguments as? [String: Any] ?? [:]
            saveSnapshotToDocuments(args: args, result: result)
        case "startVideoRecording":
            let args = call.arguments as? [String: Any] ?? [:]
            startVideoRecording(args: args, result: result)
        case "stopVideoRecording":
            stopVideoRecording(result: result)
        case "call":
            if let args = call.arguments as? [String: Any] {
                self.call(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "answer":
            if let args = call.arguments as? [String: Any] {
                answer(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "sendDtmfInfo":
            if let args = call.arguments as? [String: Any] {
                sendDtmfInfo(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "sendMessage":
            if let args = call.arguments as? [String: Any] {
                sendMessage(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "hangup":
            if let args = call.arguments as? [String: Any] {
                hangup(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "dump":
            dump(args: [:], result: result)
        case "handleIpChange":
            handleIpChange(args: [:], result: result)
        case "destroy":
            destroy(args: [:], result: result)
        case "startRecording":
            startRecording(args: [:], result: result)
        case "stopRecording":
            stopRecording(args: [:], result: result)
        case "startPlaying":
            startPlaying(args: [:], result: result)
        case "stopPlaying":
            stopPlaying(args: [:], result: result)
        case "isMute":
            isMute(args: [:], result: result)
        case "setMute":
            if let args = call.arguments as? [String: Any] {
                setMute(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "isSpeaker":
            isSpeaker(args: [:], result: result)
        case "setSpeaker":
            if let args = call.arguments as? [String: Any] {
                setSpeaker(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "setImageRatio":
            if let args = call.arguments as? [String: Any] {
                setImageRatio(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
            }
        case "clearVideo":
            clearVideo(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "queryMediaFiles":
            queryMediaFiles(result: result)
        case "migrateMediaToAppRoot":
            migrateMediaToAppRoot(result: result)
        case "loadMediaThumbnail":
            loadMediaThumbnail(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "loadMediaBytes":
            loadMediaBytes(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "playMediaVideo":
            playMediaVideo(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "saveMediaToAlbum":
            saveMediaToAlbum(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "deleteMediaFiles":
            deleteMediaFiles(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "setFTConfig":
            setFTConfig(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "setStunConfig":
            setStunConfig(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "sendFile":
            sendFile(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "requestFile":
            requestFile(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "respondRequest":
            respondRequest(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "acceptFile":
            acceptFile(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "rejectFile":
            rejectFile(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "cancelFile":
            cancelFile(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "getFileState":
            getFileState(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "createVideoPlayer":
            createVideoPlayer(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "videoPlayerPlay":
            videoPlayerPlay(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "videoPlayerPause":
            videoPlayerPause(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "videoPlayerSeekTo":
            videoPlayerSeekTo(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "videoPlayerState":
            videoPlayerState(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "disposeVideoPlayer":
            disposeVideoPlayer(args: call.arguments as? [String: Any] ?? [:], result: result)
        case "videoPlayerLastError":
            videoPlayerLastError(args: call.arguments as? [String: Any] ?? [:], result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initSDK(args: [String: Any], result: @escaping FlutterResult) {
        printSIPFrameworkVersion()
        // 1. 提取 stunConfig
        var stun: STUNConfig? = nil
        if let stunDict = args["stunConfig"] as? [String: Any] {
            let servers = (stunDict["servers"] as? [String]) ?? []
            let enableIPv6 = (stunDict["enableIPv6"] as? Bool) ?? false
            let enable = (stunDict["enable"] as? Bool) ?? true
            stun = STUNConfig(servers: servers, enableIPv6: enableIPv6, enable: enable)
        }

        // 2. 提取 mediaConfig（可选，如果你有用到）
        var mediaConfig: SIPSDKMediaConfig? = nil
        if let mediaDict = args["mediaConfig"] as? [String: Any] {
            // H264 fmtp 配置
            let h264Fmtp = mediaDict["h264Fmtp"] as? [String: Any] ?? [:]
            // 编码配置
            let encodeConfig = mediaDict["encodeConfig"] as? [String: Any] ?? [:]
            H264Encoder.econfig.fps = encodeConfig["fps"] as? Int32 ?? 20
            H264Encoder.econfig.bps = encodeConfig["bps"] as? Int32 ?? 512_000
            H264Encoder.econfig.minBps = encodeConfig["minBps"] as? Int32 ?? 256_000
            H264Encoder.econfig.maxBps = encodeConfig["maxBps"] as? Int32 ?? 1_024_000
            // 解码配置
            let decodeConfig = mediaDict["decodeConfig"] as? [String: Any] ?? [:]

            mediaConfig = SIPSDKMediaConfig(
                audioClockRate: Int32(mediaDict["audioClockRate"] as? Int ?? 16000),
                micGain: (mediaDict["micGain"] as? NSNumber)?.floatValue ?? 1.0,
                speakerGain: (mediaDict["speakerGain"] as? NSNumber)?.floatValue ?? 1.0,
                nsEnable: (mediaDict["nsEnable"] as? Bool) ?? true,
                agcEnable: (mediaDict["agcEnable"] as? Bool) ?? true,
                aecEnable: (mediaDict["aecEnable"] as? Bool) ?? true,
                aecEliminationTime: Int16(mediaDict["aecEliminationTime"] as? Int ?? 30),
                notEnableEncode: !(encodeConfig["enable"] as? Bool ?? true),
                notEnableDecode: !(decodeConfig["enable"] as? Bool ?? true),
                decodeMaxWidth: decodeConfig["maxWidth"] as? UInt32 ?? 1920,
                decodeMaxHeight: decodeConfig["maxHeight"] as? UInt32 ?? 1080,
                combinSpsPpsIdr: false, // ios 不支持组合帧 decodeConfig["combinSpsPpsIdr"] as? Bool ?? false
                profileLevelId: h264Fmtp["profileLevelId"] as? String,
                packetizationMode: h264Fmtp["packetizationMode"] as? String
            )
        } else {
            mediaConfig = SIPSDKMediaConfig()
        }

        // 配置回调
        let callbacks = SIPSDKCallbacks(
            onLogCallback: SIPManage.onLogCallback,
            onInitCompleted: SIPManage.onInitCompleted,
            onStopCompleted: SIPManage.onStopCompleted,
            onRegistrarState: SIPManage.onRegistrarState,
            onIncomingCall: SIPManage.onIncomingCall,
            onFindIncoming: SIPManage.onFindIncoming,
            onDtmfInfo: SIPManage.onDtmfInfo,
            onMessage: SIPManage.onMessage,
            onMessageState: SIPManage.onMessageState,
            onCallState: SIPManage.onCallState,
            onExpireWarning: SIPManage.onExpireWarning,
            onActivityCheck: SIPManage.onActivityCheck
        )

        // 3. 提取 SIPSDKConfig 主结构体字段
        let config = SIPSDKConfig(
            logLevel: Int32(args["logLevel"] as? Int ?? 4),
            port: args["port"] as? UInt32 ?? 5060,
            userAgent: args["userAgent"] as? String ?? "",
            workerThreadCount: Int32(args["workerThreadCount"] as? Int ?? 1),
            updateRoute: (args["updateRoute"] as? Bool) ?? false,
            enableVideo: (args["enableVideo"] as? Bool) ?? true,
            sdkObserver: callbacks,
            allowMultipleConnections: (args["allowMultipleConnections"] as? Bool) ?? false,
            domainNameDirectRegistrar: (args["domainNameDirectRegistrar"] as? Bool) ?? false,
            doesItSupportBroadcast: (args["doesItSupportBroadcast"] as? Bool) ?? false,
            customSessionName: args["customSessionName"] as? String,
            localCallUpdateTime: Int32(args["localCallUpdateTime"] as? Int ?? 60),
            stunConfig: stun
        )
        let baseUrl: String = args["baseUrl"] as? String ?? ""
        let clientId: String = args["clientId"] as? String ?? ""
        let clientSecret: String = args["clientSecret"] as? String ?? ""
        SIPHandle.initSDK(baseUrl: baseUrl,
                          clientId: clientId,
                          clientSecret: clientSecret,
                          config: config,
                          mediaConfig: mediaConfig!)
        result(nil) // 表示成功
    }

    private func initToken(args: [String: Any], result: @escaping FlutterResult) {
        printSIPFrameworkVersion()
        // 1. 提取 stunConfig
        var stun: STUNConfig? = nil
        if let stunDict = args["stunConfig"] as? [String: Any] {
            let servers = (stunDict["servers"] as? [String]) ?? []
            let enableIPv6 = (stunDict["enableIPv6"] as? Bool) ?? false
            let enable = (stunDict["enable"] as? Bool) ?? true
            stun = STUNConfig(servers: servers, enableIPv6: enableIPv6, enable: enable)
        }

        // 2. 提取 mediaConfig（可选，如果你有用到）
        var mediaConfig: SIPSDKMediaConfig? = nil
        if let mediaDict = args["mediaConfig"] as? [String: Any] {
            // H264 fmtp 配置
            let h264Fmtp = mediaDict["h264Fmtp"] as? [String: Any] ?? [:]
            // 编码配置
            let encodeConfig = mediaDict["encodeConfig"] as? [String: Any] ?? [:]
            H264Encoder.econfig.fps = encodeConfig["fps"] as? Int32 ?? 20
            H264Encoder.econfig.bps = encodeConfig["bps"] as? Int32 ?? 512_000
            H264Encoder.econfig.minBps = encodeConfig["minBps"] as? Int32 ?? 256_000
            H264Encoder.econfig.maxBps = encodeConfig["maxBps"] as? Int32 ?? 1_024_000
            // 解码配置
            let decodeConfig = mediaDict["decodeConfig"] as? [String: Any] ?? [:]

            mediaConfig = SIPSDKMediaConfig(
                audioClockRate: Int32(mediaDict["audioClockRate"] as? Int ?? 16000),
                micGain: (mediaDict["micGain"] as? NSNumber)?.floatValue ?? 1.0,
                speakerGain: (mediaDict["speakerGain"] as? NSNumber)?.floatValue ?? 1.0,
                nsEnable: (mediaDict["nsEnable"] as? Bool) ?? true,
                agcEnable: (mediaDict["agcEnable"] as? Bool) ?? true,
                aecEnable: (mediaDict["aecEnable"] as? Bool) ?? true,
                aecEliminationTime: Int16(mediaDict["aecEliminationTime"] as? Int ?? 30),
                notEnableEncode: !(encodeConfig["enable"] as? Bool ?? true),
                notEnableDecode: !(decodeConfig["enable"] as? Bool ?? true),
                decodeMaxWidth: decodeConfig["maxWidth"] as? UInt32 ?? 1920,
                decodeMaxHeight: decodeConfig["maxHeight"] as? UInt32 ?? 1080,
                combinSpsPpsIdr: false, // ios 不支持组合帧 decodeConfig["combinSpsPpsIdr"] as? Bool ?? false
                profileLevelId: h264Fmtp["profileLevelId"] as? String,
                packetizationMode: h264Fmtp["packetizationMode"] as? String
            )
        } else {
            mediaConfig = SIPSDKMediaConfig()
        }

        // 配置回调
        let callbacks = SIPSDKCallbacks(
            onLogCallback: SIPManage.onLogCallback,
            onInitCompleted: SIPManage.onInitCompleted,
            onStopCompleted: SIPManage.onStopCompleted,
            onRegistrarState: SIPManage.onRegistrarState,
            onIncomingCall: SIPManage.onIncomingCall,
            onFindIncoming: SIPManage.onFindIncoming,
            onDtmfInfo: SIPManage.onDtmfInfo,
            onMessage: SIPManage.onMessage,
            onMessageState: SIPManage.onMessageState,
            onCallState: SIPManage.onCallState,
            onExpireWarning: SIPManage.onExpireWarning,
            onActivityCheck: SIPManage.onActivityCheck
        )

        // 3. 提取 SIPSDKConfig 主结构体字段
        let config = SIPSDKConfig(
            logLevel: Int32(args["logLevel"] as? Int ?? 4),
            port: args["port"] as? UInt32 ?? 5060,
            userAgent: args["userAgent"] as? String ?? "",
            workerThreadCount: Int32(args["workerThreadCount"] as? Int ?? 1),
            updateRoute: (args["updateRoute"] as? Bool) ?? false,
            enableVideo: (args["enableVideo"] as? Bool) ?? true,
            sdkObserver: callbacks,
            allowMultipleConnections: (args["allowMultipleConnections"] as? Bool) ?? false,
            domainNameDirectRegistrar: (args["domainNameDirectRegistrar"] as? Bool) ?? false,
            doesItSupportBroadcast: (args["doesItSupportBroadcast"] as? Bool) ?? false,
            customSessionName: args["customSessionName"] as? String,
            localCallUpdateTime: Int32(args["localCallUpdateTime"] as? Int ?? 60),
            stunConfig: stun
        )
        let token: String = args["token"] as? String ?? ""
        let clientId: String = args["clientId"] as? String ?? ""
        let clientSecret: String = args["clientSecret"] as? String ?? ""
        SIPHandle.initToken(token: token,
                            clientId: clientId,
                            clientSecret: clientSecret,
                            config: config,
                            mediaConfig: mediaConfig!)
        result(nil) // 表示成功
    }

    private func localAccount(args: [String: Any], result _: @escaping FlutterResult) {
        let localConfig = REGLocalConfig(
            transport: args["transport"] as? String,
            username: args["username"] as? String,
            port: uint32Value(args["port"], default: 58581),
            boundAddr: args["boundAddr"] as? String,
            publicAddr: args["publicAddr"] as? String,
            enableStreamControl: (args["enableStreamControl"] as? Bool) ?? false,
            streamElapsed: Int32(args["streamElapsed"] as? Int ?? 0),
            lockCodec: uint32Value(args["lockCodec"])
        )

        SIPHandle.localAccount(localConfig: localConfig)
    }

    private func remoteAccount(args: [String: Any], result: @escaping FlutterResult) {
        var turnConfig: TURNConfig?
        if let turnConfigDict = args["turnConfig"] as? [String: Any] {
            let enable = (turnConfigDict["enable"] as? Bool) ?? false
            let server = turnConfigDict["server"] as? String
            let realm = turnConfigDict["realm"] as? String
            let username = turnConfigDict["username"] as? String
            let password = turnConfigDict["password"] as? String

            turnConfig = TURNConfig(
                enable: enable,
                server: server,
                realm: realm,
                username: username,
                password: password
            )
        }

        let headers = (args["headers"] as? [String: String])?.map { ($0.key, $0.value) }

        let domain = args["domain"] as? String
        let username = args["username"] as? String
        let password = args["password"] as? String
        let transport = args["transport"] as? String
        let serverAddr = args["serverAddr"] as? String
        let serverPort = uint32Value(args["serverPort"], default: 5060)
        let proxy = args["proxy"] as? String
        let proxyPort = uint32Value(args["proxyPort"])
        let srtpKeying = (args["srtpKeying"] as? Bool)
            ?? (args["srtpKeying"] as? NSNumber)?.boolValue
            ?? false
        let enableStreamControl = (args["enableStreamControl"] as? Bool) ?? false
        let streamElapsed = Int32(args["streamElapsed"] as? Int ?? 0)
        let lockCodec = uint32Value(args["lockCodec"])

        let config = REGConfig(
            domain: domain,
            username: username,
            password: password,
            transport: transport,
            serverAddr: serverAddr,
            serverPort: serverPort,
            headers: headers,
            proxy: proxy,
            proxyPort: proxyPort,
            srtpKeying: srtpKeying,
            enableStreamControl: enableStreamControl,
            streamElapsed: streamElapsed,
            lockCodec: lockCodec,
            turnConfig: turnConfig
        )

        SIPHandle.remoteAccount(config: config)
        result(nil) // 表示成功
    }

    /**
     * 解除注册到服务器
     */
    private func delRemoteAccount(args _: [String: Any], result: @escaping FlutterResult) {
        SIPHandle.delRemoteAccount()
        result(nil)
    }

    /**
     * 打开摄像头
     */
    private func cameraOpen(args: [String: Any], result: @escaping FlutterResult) {
        let index = Int(args["index"] as? Int ?? 1)
        let width = Int(args["width"] as? Int ?? 640)
        let height = Int(args["height"] as? Int ?? 480)
        CameraCaptureManager.shared.start(index: index, width: width, height: height)
        result(nil)
    }

    /**
     * 关闭摄像头
     */
    private func cameraClose(args _: [String: Any], result: @escaping FlutterResult) {
        CameraCaptureManager.shared.stop()
        result(nil)
    }

    private func captureSnapshot(args _: [String: Any], result: @escaping FlutterResult) {
        guard let view = VideoComponentView.currentInstance else {
            result(nil)
            return
        }
        view.captureSnapshot { data in
            guard let data else {
                result(nil)
                return
            }
            result(FlutterStandardTypedData(bytes: data))
        }
    }

    /**
     * 截取对方视频画面并保存为 JPG 到 relativePath 指定的位置。
     * relativePath 是相对媒体根目录的完整路径（含文件名），如
     * Doorbell/<deviceId>/photo/2026/08/10/101530_123.jpg。
     * iOS 无外部存储概念，保存到应用 Documents 目录下，
     * 宿主开启文件共享后可通过 Finder/iTunes 导出。
     */
    private func saveSnapshotToDocuments(args: [String: Any], result: @escaping FlutterResult) {
        guard let relativePath = args["relativePath"] as? String,
              !relativePath.isEmpty else {
            result(nil)
            return
        }
        guard let view = VideoComponentView.currentInstance else {
            result(nil)
            return
        }
        view.captureSnapshot { data in
            guard let data, let image = UIImage(data: data) else {
                result(nil)
                return
            }
            guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
                result(nil)
                return
            }
            let docs = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true).first ?? ""
            let fileURL = URL(
                fileURLWithPath: (docs as NSString).appendingPathComponent(relativePath))
            do {
                try FileManager.default.createDirectory(
                    atPath: fileURL.deletingLastPathComponent().path,
                    withIntermediateDirectories: true, attributes: nil)
                try jpegData.write(to: fileURL)
                result(fileURL.path)
            } catch {
                result(FlutterError(
                    code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
            }
        }
    }

    /**
     * 开始录制对方视频画面为 MP4，保存到 Documents/<relativePath>。
     * 与 Android 的 CallMediaRecorder 语义一致：返回文件绝对路径。
     */
    private func startVideoRecording(args: [String: Any], result: @escaping FlutterResult) {
        guard let relativePath = args["relativePath"] as? String,
              !relativePath.isEmpty else {
            result(nil)
            return
        }
        guard let view = VideoComponentView.currentInstance?.view() else {
            result(nil)
            return
        }
        let path = VideoRecorderManager.shared.startRecording(
            view: view, relativePath: relativePath)
        result(path)
    }

    /**
     * 停止录制，返回录制文件绝对路径；失败或无文件时返回 nil。
     */
    private func stopVideoRecording(result: @escaping FlutterResult) {
        VideoRecorderManager.shared.stopRecording { path in
            result(path)
        }
    }

    /**
     * 通过服务器呼叫
     * username: 对方用户名
     * headers: 自定义头信息
     */
    private func call(args: [String: Any], result: @escaping FlutterResult) {
        let param = CallParam(
            type: Int32(args["type"] as? Int32 ?? SDK_CALL_TYPE_SERVER.rawValue),
            username: args["username"] as? String,
            remoteIp: args["remoteIp"] as? String,
            headers: (args["headers"] as? [String: String])?.map { ($0.key, $0.value) },
            transmitVideo: (args["transmitVideo"] as? Bool) ?? true,
            transmitSound: (args["transmitSound"] as? Bool) ?? true
        )

        let callUuid: UInt64 = SIPHandle.call(param: param)
        result(String(callUuid))
    }

    /**
     * 接听呼叫
     * code: 接听状态码，正常接听200，先通媒体183
     * callUuid: 接听所有0，接听指定呼叫不等于0
     */
    private func answer(args: [String: Any], result: @escaping FlutterResult) {
        let code = uint32Value(args["code"], default: 200)
        let callUuid = uint64Value(args["callUuid"])
        SIPHandle.answer(code: code, callUuid: callUuid)
        result(nil)
    }

    /**
     * 发送info消息
     * type: 消息类型
     * contentType: 内容类型
     * content: 内容（除自定义类型外、其他的类型内容只能是一个字节）
     * callUuid: 为0所有呼叫发送，不等于0指定呼叫发送
     */
    private func sendDtmfInfo(args: [String: Any], result: @escaping FlutterResult) {
        let dtmfInfoType = Int32(args["dtmfInfoType"] as? Int ?? args["type"] as? Int ?? 0)
        let content = args["content"] as? String ?? ""
        let callUuid = uint64Value(args["callUuid"])
        // 发送
        SIPHandle.sendDtmfInfo(type: dtmfInfoType, callUuid: callUuid, content: content)
        // 成功回调
        result(nil)
    }

    /**
     * 通过服务器发送sip message消息
     * username: 对方账号
     * content: 内容
     */
    private func sendMessage(args: [String: Any], result: @escaping FlutterResult) {
        let param = MessageParam(
            type: Int32(args["type"] as? Int32 ?? SDK_MESSAGE_TYPE_SERVER.rawValue),
            content: args["content"] as? String ?? "",
            username: args["username"] as? String,
            remoteIp: args["remoteIp"] as? String
        )

        // 发送
        SIPHandle.sendMessage(param: param)
        // 成功回调
        result(nil)
    }

    /**
     * 挂断 call_uuid 对应的呼叫
     * code: 挂断状态码，正常挂断200
     * callUuid: 为0挂断所有呼叫，不等于0挂断指定呼叫
     */
    private func hangup(args: [String: Any], result: @escaping FlutterResult) {
        let code = uint32Value(args["code"], default: 200)
        let callUuid = uint64Value(args["callUuid"])
        SIPHandle.hangup(code: code, callUuid: callUuid)
        result(nil)
    }

    /**
     *  打印SDK信息，包括所有内存使用信息
     */
    private func dump(args _: [String: Any], result: @escaping FlutterResult) {
        SIPHandle.dump()
        result(nil)
    }

    /**
     *  IP 发生改变调用
     */
    private func handleIpChange(args: [String: Any], result: @escaping FlutterResult) {
        let restart = (args["restart"] as? Bool) ?? true
        let restartDelay = uint32Value(args["restartDelay"], default: 500)
        SIPHandle.handleIpChange(restart: restart, restartDelay: restartDelay)
        result(nil)
    }

    /**
     *  销毁
     */
    private func destroy(args _: [String: Any], result: @escaping FlutterResult) {
        SIPHandle.destroy()
        result(nil)
    }

    /**
     *  开始录音
     */
    private func startRecording(args _: [String: Any], result: @escaping FlutterResult) {
        PCMRecorder.instance.start()
        result(nil)
    }

    /**
     *  停止录音
     */
    private func stopRecording(args _: [String: Any], result: @escaping FlutterResult) {
        PCMRecorder.instance.stop()
        result(nil)
    }

    /**
     *  开始播放
     */
    private func startPlaying(args _: [String: Any], result: @escaping FlutterResult) {
        PCMPlayer.instance.start()
        result(nil)
    }

    /**
     *  停止播放
     */
    private func stopPlaying(args _: [String: Any], result: @escaping FlutterResult) {
        PCMPlayer.instance.stop()
        result(nil)
    }

    /**
     *  是否静音
     */
    private func isMute(args _: [String: Any], result: @escaping FlutterResult) {
        let mute: Bool = PCMRecorder.instance.muteEnabled()
        result(mute)
    }

    /**
     *  设置静音
     */
    private func setMute(args: [String: Any], result: @escaping FlutterResult) {
        let mute: Bool = (args["mute"] as? Bool) ?? false
        PCMRecorder.instance.setMute(enabled: mute)
        result(nil)
    }

    /**
     *  是否speaker
     */
    private func isSpeaker(args _: [String: Any], result: @escaping FlutterResult) {
        let speak = PCMPlayer.instance.speakerEnabled()
        result(speak)
    }

    /**
     *  设置Speaker
     */
    private func setSpeaker(args: [String: Any], result: @escaping FlutterResult) {
        let speaker: Bool = (args["speaker"] as? Bool) ?? true
        PCMPlayer.instance.setSpeaker(enabled: speaker)
        result(nil)
    }

    private func setImageRatio(args: [String: Any], result: @escaping FlutterResult) {
        let originalRatio: Bool = (args["originalRatio"] as? Bool) ?? false
        VideoComponentView.currentInstance?.setImageRatio(originalRatio: originalRatio)
        result(nil)
    }

    private func clearVideo(args: [String: Any], result: @escaping FlutterResult) {
        VideoComponentView.currentInstance?.clearVideo()
        result(nil)
    }

    // MARK: - 相册（拍照/录制视频）读取

    /**
     * 枚举应用 Documents/ParsianTasvir/Doorbell 下的所有拍照 / 录制视频。
     * 返回 [{relativePath, uri}]，uri 为绝对文件路径，
     * relativePath 统一为 Doorbell/<deviceKey>/<type>/<yyyy>/<MM>/<dd>/<file>
     * （剥掉 app 根前缀 ParsianTasvir/，与 Dart 侧解析约定一致）。
     */
    private func queryMediaFiles(result: @escaping FlutterResult) {
        let docs = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true).first ?? ""
        let root = (docs as NSString).appendingPathComponent("ParsianTasvir/Doorbell")
        result(walkMediaDir(root, prefix: "Doorbell"))
    }

    /**
     * 一次性迁移旧媒体目录（Doorbell / lastframe / callrecord）到 app 公共根目录
     * ParsianTasvir/ 下，方便统一清理。幂等：根目录已存在则跳过。
     */
    private func migrateMediaToAppRoot(result: @escaping FlutterResult) {
        let docs = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true).first ?? ""
        let appRoot = (docs as NSString).appendingPathComponent("ParsianTasvir")
        let fm = FileManager.default
        guard !fm.fileExists(atPath: appRoot) else {
            result(true)
            return
        }
        try? fm.createDirectory(atPath: appRoot, withIntermediateDirectories: true)
        for sub in ["Doorbell", "lastframe", "callrecord"] {
            let src = (docs as NSString).appendingPathComponent(sub)
            if fm.fileExists(atPath: src) {
                try? fm.moveItem(
                    atPath: src,
                    toPath: (appRoot as NSString).appendingPathComponent(sub))
            }
        }
        result(true)
    }

    private func walkMediaDir(_ dir: String, prefix: String) -> [[String: String]] {
        var out: [[String: String]] = []
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { return out }
        for entry in entries {
            let path = (dir as NSString).appendingPathComponent(entry)
            let relative = prefix + "/" + entry
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: path, isDirectory: &isDir) {
                if isDir.boolValue {
                    out.append(contentsOf: walkMediaDir(path, prefix: relative))
                } else if isMediaFile(entry) {
                    out.append(["relativePath": relative, "uri": path])
                }
            }
        }
        return out
    }

    private func isMediaFile(_ name: String) -> Bool {
        let n = name.lowercased()
        return n.hasSuffix(".jpg") || n.hasSuffix(".jpeg")
            || n.hasSuffix(".png") || n.hasSuffix(".mp4")
    }

    private func loadMediaThumbnail(args: [String: Any], result: @escaping FlutterResult) {
        guard let uri = args["uri"] as? String, !uri.isEmpty else {
            result(nil)
            return
        }
        let maxSize = args["maxSize"] as? Int ?? 256
        DispatchQueue.global(qos: .userInitiated).async {
            let data = self.mediaThumbnailData(for: uri, maxSize: maxSize)
            DispatchQueue.main.async {
                if let data = data {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(nil)
                }
            }
        }
    }

    private func mediaThumbnailData(for uri: String, maxSize: Int) -> Data? {
        let url = URL(fileURLWithPath: uri)
        if uri.lowercased().hasSuffix(".mp4") {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: maxSize * 2, height: maxSize * 2)
            let time = CMTime(value: 0, timescale: 600)
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
            }
            return nil
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize * 2
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8)
    }

    private func loadMediaBytes(args: [String: Any], result: @escaping FlutterResult) {
        guard let uri = args["uri"] as? String, !uri.isEmpty else {
            result(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let data = try? Data(contentsOf: URL(fileURLWithPath: uri))
            DispatchQueue.main.async {
                if let data = data {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(nil)
                }
            }
        }
    }

    private func playMediaVideo(args: [String: Any], result: @escaping FlutterResult) {
        guard let uri = args["uri"] as? String, !uri.isEmpty else {
            result(nil)
            return
        }
        DispatchQueue.main.async {
            let player = AVPlayer(url: URL(fileURLWithPath: uri))
            let controller = AVPlayerViewController()
            controller.player = player
            guard let top = self.topViewController() else {
                result(nil)
                return
            }
            top.present(controller, animated: true) {
                player.play()
            }
            result(nil)
        }
    }

    private func saveMediaToAlbum(args: [String: Any], result: @escaping FlutterResult) {
        guard let uri = args["uri"] as? String, !uri.isEmpty else {
            result(false)
            return
        }
        let fileURL = URL(fileURLWithPath: uri)
        let isVideo = uri.lowercased().hasSuffix(".mp4")
        // 只新增到相册、不读取。iOS 14+ 用 .addOnly(仅需 NSPhotoLibraryAddUsageDescription)，
        // 避免向用户索要整个相册读写权限；iOS 13 及更早没有 .addOnly，只能用全量
        // requestAuthorization(依赖 Info.plist 的 NSPhotoLibraryUsageDescription)。
        let handleAuth: (PHAuthorizationStatus) -> Void = { status in
            let allowed: Bool
            if #available(iOS 14, *) {
                allowed = status == .authorized || status == .limited
            } else {
                allowed = status == .authorized
            }
            guard allowed else {
                DispatchQueue.main.async { result(false) }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                if isVideo {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                } else {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                }
            } completionHandler: { success, _ in
                DispatchQueue.main.async { result(success) }
            }
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: handleAuth)
        } else {
            // iOS 13 旧 API 参数无标签
            PHPhotoLibrary.requestAuthorization(handleAuth)
        }
    }

    private func deleteMediaFiles(args: [String: Any], result: @escaping FlutterResult) {
        let uris = args["uris"] as? [String] ?? []
        guard !uris.isEmpty else {
            result(false)
            return
        }
        DispatchQueue.global().async {
            var ok = true
            for u in uris {
                let url = URL(fileURLWithPath: u)
                if FileManager.default.fileExists(atPath: url.path) {
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        ok = false
                    }
                }
            }
            DispatchQueue.main.async { result(ok) }
        }
    }

    // MARK: - 文件传输（FT）

    /**
     * 配置文件传输（需在 initSDK/initToken 之前调用，FT 模块随 SDK init 自动启用）。
     * 返回值：状态码（0 成功，负数为错误码）。
     */
    /// 单独设置 STUN（运行期接口，服务端地址变更后重新调用即可，不需要重启 SDK）。
    /// 注意 enable 缺省按 Dart 侧的 false 走（initSDK 里那处历史缺省是 true）。
    private func setStunConfig(args: [String: Any], result: @escaping FlutterResult) {
        let servers = (args["servers"] as? [String]) ?? []
        let enableIPv6 = (args["enableIPv6"] as? Bool) ?? false
        let enable = (args["enable"] as? Bool) ?? false
        let stun = STUNConfig(servers: servers, enableIPv6: enableIPv6, enable: enable)
        result(Int(SIPHandle.setStunConfig(stun)))
    }

    private func setFTConfig(args: [String: Any], result: @escaping FlutterResult) {
        var stun: STUNConfig?
        if let stunDict = args["stun"] as? [String: Any] {
            let servers = (stunDict["servers"] as? [String]) ?? []
            let enableIPv6 = (stunDict["enableIPv6"] as? Bool) ?? false
            let enable = (stunDict["enable"] as? Bool) ?? true
            if !servers.isEmpty {
                stun = STUNConfig(servers: servers, enableIPv6: enableIPv6, enable: enable)
            }
        }
        var turn: TURNConfig?
        if let turnDict = args["turn"] as? [String: Any] {
            turn = TURNConfig(
                enable: (turnDict["enable"] as? Bool) ?? false,
                server: turnDict["server"] as? String,
                realm: turnDict["realm"] as? String,
                username: turnDict["username"] as? String,
                password: turnDict["password"] as? String
            )
        }
        let config = SIPFTConfig(
            enable: (args["enable"] as? Bool) ?? false,
            maxSessions: uint32Value(args["maxSessions"]),
            windowSize: uint32Value(args["windowSize"]),
            chunkSize: uint32Value(args["chunkSize"]),
            initialRtoMs: uint32Value(args["initialRtoMs"]),
            rtoMinMs: uint32Value(args["rtoMinMs"]),
            maxRetransmit: uint32Value(args["maxRetransmit"]),
            sessionTimeoutMs: uint32Value(args["sessionTimeoutMs"]),
            answerTimeoutMs: uint32Value(args["answerTimeoutMs"]),
            connectTimeoutMs: uint32Value(args["connectTimeoutMs"]),
            inactiveTimeoutMs: uint32Value(args["inactiveTimeoutMs"]),
            burstMax: uint32Value(args["burstMax"]),
            sendIntervalMs: uint32Value(args["sendIntervalMs"]),
            kcpSndwnd: uint32Value(args["kcpSndwnd"]),
            kcpRcvwnd: uint32Value(args["kcpRcvwnd"]),
            kcpMaxWaitsnd: uint32Value(args["kcpMaxWaitsnd"]),
            kcpDisableCc: (args["kcpDisableCc"] as? Bool) ?? false,
            stun: stun,
            turn: turn,
            enableIpv6: (args["enableIpv6"] as? Bool) ?? false,
            defaultSaveDir: args["defaultSaveDir"] as? String
        )
        let code = SIPManage.setupFTConfig(config: config)
        result(code)
    }

    /**
     * 发送文件（异步）。返回 {code, ftId, reqId:0}。
     */
    private func sendFile(args: [String: Any], result: @escaping FlutterResult) {
        let ret = SIPHandle.sendFile(
            accUuid: uint64Value(args["accUuid"]),
            username: args["username"] as? String,
            remoteIp: args["remoteIp"] as? String,
            filePath: args["filePath"] as? String ?? "",
            extra: args["extra"] as? String
        )
        result([
            "code": ret.code,
            "ftId": ret.ftId,
            "reqId": 0,
        ])
    }

    /**
     * 请求对端发送文件（pull，异步）。返回 {code, reqId, ftId:0}。
     */
    private func requestFile(args: [String: Any], result: @escaping FlutterResult) {
        let ret = SIPHandle.requestFile(
            accUuid: uint64Value(args["accUuid"]),
            username: args["username"] as? String,
            remoteIp: args["remoteIp"] as? String,
            fileName: args["fileName"] as? String ?? "",
            extra: args["extra"] as? String
        )
        result([
            "code": ret.code,
            "reqId": ret.reqId,
            "ftId": 0,
        ])
    }

    /**
     * 回应对端的文件请求（accept=true 同意并给本地文件路径，false 拒绝）。
     */
    private func respondRequest(args: [String: Any], result: @escaping FlutterResult) {
        let code = SIPHandle.respondRequest(
            reqId: uint64Value(args["reqId"]),
            accept: (args["accept"] as? Bool) ?? false,
            filePath: args["filePath"] as? String
        )
        result(code)
    }

    /**
     * 接受对端的文件传输请求。
     */
    private func acceptFile(args: [String: Any], result: @escaping FlutterResult) {
        let code = SIPHandle.acceptFile(
            ftId: uint64Value(args["ftId"]),
            savePath: args["savePath"] as? String
        )
        result(code)
    }

    /**
     * 拒绝对端的文件传输请求。
     */
    private func rejectFile(args: [String: Any], result: @escaping FlutterResult) {
        let code = SIPHandle.rejectFile(
            ftId: uint64Value(args["ftId"]),
            reason: args["reason"] as? String
        )
        result(code)
    }

    /**
     * 取消传输（发送端或接收端均可）。
     */
    private func cancelFile(args: [String: Any], result: @escaping FlutterResult) {
        let code = SIPHandle.cancelFile(ftId: uint64Value(args["ftId"]))
        result(code)
    }

    /**
     * 查询会话状态（成功返回 state 枚举，失败返回负错误码）。
     */
    private func getFileState(args: [String: Any], result: @escaping FlutterResult) {
        let state = SIPHandle.getFileState(ftId: uint64Value(args["ftId"]))
        result(state)
    }

    // MARK: - 内嵌文件视频播放（createVideoPlayer / videoPlayer*）

    /// Dart 侧 textureId（平台 int）转 Int64。
    private func textureIdValue(_ value: Any?) -> Int64 {
        if let v = value as? Int64 { return v }
        if let v = value as? Int { return Int64(v) }
        if let v = value as? NSNumber { return v.int64Value }
        return 0
    }

    /// 把门铃录像 .AVI 无损重封装成临时目录里的 MP4（AVPlayer 解不了 AVI）。
    /// 纯函数：不触碰实例状态（不写 lastVideoPlayerError），返回 (url, 失败原因)，
    /// 以便放到后台队列执行，避免在主线程上做几 MB 的拷贝拖慢引擎首帧/UI。
    private static func remuxAviToTempMp4(_ path: String) -> (url: URL?, error: String?) {
        do {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("parsian_\(UUID().uuidString).mp4")
            let stats = try AviToMp4Remuxer.remux(
                from: URL(fileURLWithPath: path), to: tmp)
            guard stats.frameCount > 0 else {
                NSLog("[SIPSDK] remux fail: 0 frames path=%@", path)
                return (nil, "remux: 0 frames")
            }
            NSLog("[SIPSDK] remux ok frames=%ld %ldx%ld durMs=%ld -> %@",
                  stats.frameCount, stats.width, stats.height,
                  stats.durationMs, tmp.path)
            return (tmp, nil)
        } catch {
            NSLog("[SIPSDK] remux AVI failed: %@ path=%@",
                  String(describing: error), path)
            return (nil, "remux: \(error)")
        }
    }

    /// 创建内嵌播放器：返回 textureId（Dart 用 Texture(textureId:) 显示）；
    /// 门铃视频/照片都先落到本地再展示，iOS 侧传入的是绝对路径（或 file://）。
    /// 失败返回 null，Dart 按「打开失败」提示。
    private func createVideoPlayer(args: [String: Any], result: @escaping FlutterResult) {
        guard let uri = args["uri"] as? String, !uri.isEmpty else {
            lastVideoPlayerError = "uri empty"
            NSLog("[SIPSDK] createVideoPlayer FAIL: uri empty")
            result(nil)
            return
        }
        guard let registry = textureRegistry else {
            lastVideoPlayerError = "textureRegistry nil"
            NSLog("[SIPSDK] createVideoPlayer FAIL: textureRegistry nil uri=%@", uri)
            result(nil)
            return
        }
        let path: String
        if uri.hasPrefix("file://"), let u = URL(string: uri) {
            path = u.path
        } else {
            path = uri
        }
        NSLog("[SIPSDK] createVideoPlayer uri=%@", path)
        guard FileManager.default.fileExists(atPath: path) else {
            lastVideoPlayerError = "file not found"
            NSLog("[SIPSDK] createVideoPlayer FAIL: file not found %@", path)
            result(nil)
            return
        }

        // 非 AVI（已是 AVPlayer 能播的 MP4 等）：直接建播放器（带注册重试）。
        guard path.lowercased().hasSuffix(".avi") else {
            attemptPlayerStart(url: URL(fileURLWithPath: path),
                               deleteOnClose: false,
                               registry: registry,
                               sourcePath: path,
                               retriesLeft: 8,
                               result: result)
            return
        }

        // 门铃录像原始容器是 AVI：先重封装成临时 MP4 再交给 AVPlayer。
        // remux 放到后台队列，不阻塞主线程（阻塞会拖到引擎首帧渲染）。
        lastVideoPlayerError = nil
        DispatchQueue.global(qos: .userInitiated).async {
            let r = Self.remuxAviToTempMp4(path)
            DispatchQueue.main.async {
                guard let mp4 = r.url else {
                    self.lastVideoPlayerError = r.error ?? "remux nil"
                    NSLog("[SIPSDK] createVideoPlayer FAIL: remux nil uri=%@", path)
                    result(nil)
                    return
                }
                self.attemptPlayerStart(url: mp4,
                                        deleteOnClose: true,
                                        registry: registry,
                                        sourcePath: path,
                                        retriesLeft: 8,
                                        result: result)
            }
        }
    }

    /// 建 NativeFilePlayer 并注册纹理。冷启动后第一次 registerTexture 偶发返回 0
    /// （日志 `registerTexture returned 0`，引擎纹理管线尚在预热，紧跟着往往是
    /// AVFoundation 的 FigApplicationStateMonitor 告警）；同一文件第二次打开总能成功。
    /// 故注册失败时不直接判失败，而是在主线程短延时让步给引擎后重试几次。
    /// NativeFilePlayer init 返回 nil 只有两种可能：文件缺失（此处已确保存在）、
    /// registerTexture 返回 0，所以 nil 就等价于注册失败，可放心重试。
    private func attemptPlayerStart(url playURL: URL,
                                    deleteOnClose: Bool,
                                    registry: FlutterTextureRegistry,
                                    sourcePath: String,
                                    retriesLeft: Int,
                                    result: @escaping FlutterResult) {
        guard FileManager.default.fileExists(atPath: playURL.path) else {
            lastVideoPlayerError = "tmp file missing"
            NSLog("[SIPSDK] createVideoPlayer FAIL: tmp file missing %@",
                  playURL.path)
            result(nil)
            return
        }
        if let p = NativeFilePlayer(fileURL: playURL,
                                    deleteOnClose: deleteOnClose,
                                    registry: registry) {
            lastVideoPlayerError = nil
            nativePlayers[p.textureId] = p
            p.start()
            NSLog("[SIPSDK] createVideoPlayer OK textureId=%lld uri=%@",
                  p.textureId, sourcePath)
            result(NSNumber(value: p.textureId))
            return
        }
        guard retriesLeft > 0 else {
            lastVideoPlayerError = "registerTexture returned 0"
            NSLog("[SIPSDK] createVideoPlayer FAIL after retries: registerTexture 0 uri=%@",
                  sourcePath)
            if deleteOnClose { try? FileManager.default.removeItem(at: playURL) }
            result(nil)
            return
        }
        NSLog("[SIPSDK] registerTexture returned 0, retry in 120ms (left=%ld) uri=%@",
              retriesLeft, sourcePath)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.attemptPlayerStart(url: playURL,
                                    deleteOnClose: deleteOnClose,
                                    registry: registry,
                                    sourcePath: sourcePath,
                                    retriesLeft: retriesLeft - 1,
                                    result: result)
        }
    }

    /// Dart 侧 createVideoPlayer 拿到 null 后调用，取回失败原因。
    private func videoPlayerLastError(args: [String: Any], result: @escaping FlutterResult) {
        result(lastVideoPlayerError ?? "")
    }

    private func videoPlayerPlay(args: [String: Any], result: @escaping FlutterResult) {
        nativePlayers[textureIdValue(args["textureId"])]?.play()
        result(nil)
    }

    private func videoPlayerPause(args: [String: Any], result: @escaping FlutterResult) {
        nativePlayers[textureIdValue(args["textureId"])]?.pause()
        result(nil)
    }

    private func videoPlayerSeekTo(args: [String: Any], result: @escaping FlutterResult) {
        let ms = (args["ms"] as? NSNumber)?.intValue ?? 0
        nativePlayers[textureIdValue(args["textureId"])]?.seek(toMilliseconds: ms)
        result(nil)
    }

    /// 查询播放状态：{position, duration, playing, videoWidth, videoHeight}。
    private func videoPlayerState(args: [String: Any], result: @escaping FlutterResult) {
        let tid = textureIdValue(args["textureId"])
        if let p = nativePlayers[tid] {
            let s = p.state()
            // AVPlayer 播放期错误（非 create 阶段）也记录，Dart 可取回展示。
            if let e = s["error"] as? String, !e.isEmpty {
                lastVideoPlayerError = "state: \(e)"
            }
            result(s)
        } else {
            result(["position": 0, "duration": 0, "playing": false])
        }
    }

    private func disposeVideoPlayer(args: [String: Any], result: @escaping FlutterResult) {
        nativePlayers.removeValue(forKey: textureIdValue(args["textureId"]))?.dispose()
        result(nil)
    }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? scenes.compactMap { $0 as? UIWindowScene }.first
        let window = windowScene?.windows.first { $0.isKeyWindow }
            ?? windowScene?.windows.first
        guard let root = window?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
