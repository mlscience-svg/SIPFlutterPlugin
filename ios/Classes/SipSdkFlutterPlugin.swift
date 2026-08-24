import Flutter
import SIPFramework
import UIKit
import AVFoundation
import AVKit
import ImageIO
import Photos

public class SipSdkFlutterPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?

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
        SipSdkFlutterPlugin.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        // 注册视频界面
        let factory = VideoComponentFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.sip.flutter/VideoComponentView")
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
            stun = STUNConfig(servers: servers, enableIPv6: enableIPv6)
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
            stun = STUNConfig(servers: servers, enableIPv6: enableIPv6)
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
        PHPhotoLibrary.requestAuthorization { status in
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
