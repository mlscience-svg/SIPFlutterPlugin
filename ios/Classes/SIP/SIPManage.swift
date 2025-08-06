//
//  SIPManage.swift
//  SIPSDKExample
//
//  Created by 杨涛 on 2025/5/18.
//

import AVFoundation
import SIPFramework

public extension Notification.Name {
    static let SIP_CALL_STATE_CHANGE = Notification.Name("SIP_CALL_STATE_CHANGE")
}

public class SIPManage {
    // 定义符合 C 调用约定的回调函数
    static let onLogCallback: OnLogCallback = { level, data, _ in
        let levelText: String
        switch level {
        case 0: levelText = "DEBUG"
        case 1: levelText = "INFO"
        case 2: levelText = "WARN"
        case 3: levelText = "ERROR"
        default: levelText = "UNKNOWN"
        }

        if let data = data {
            let message = String(cString: data)
            print("[\(levelText)] \(message)")
        } else {
            print("[\(levelText)] <no message>")
        }
    }

    static let onInitCompleted: OnInitCompleted = { state, msg in
        var message: String?
        if let msg = msg {
            message = String(cString: msg)
            print("SDK Init completed. State: \(state), Message: \(message ?? "nil")")
        } else {
            print("SDK Init completed. State: \(state), No message.")
        }
        let payload: [String: Any] = [
            "state": state,
            "message": message ?? "",
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onInitCompleted", arguments: payload)
    }

    static let onStopCompleted: OnStopCompleted = {
        print("SDK stopped.")
        SipSdkFlutterPlugin.channel?.invokeMethod("onStopCompleted", arguments: nil)
    }

    static let onRegistrarState: OnRegistrarState = { state in
        print("Registrar state: \(state)")
        // 注册状态改变
        let payload: [String: Any] = [
            "state": state,
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onRegistrarState", arguments: payload)
    }

    static let onIncomingCall: OnIncomingCall = { callParam in
        print("Incoming call with params: \(callParam)")
        var headers = [String: String]()
        // 使用 withUnsafePointer 获取 headers 指针
        withUnsafePointer(to: callParam.headers) { headersPtr in
            // 将 headers 指针转换为原始字节缓冲区
            let rawPtr = UnsafeRawPointer(headersPtr)
            // 绑定内存为 sip_header 类型
            let buffer = rawPtr.bindMemory(to: sip_header.self, capacity: Int(SDK_MAX_CUSTOM_HEADERS))
            // 遍历数组
            for i in 0 ..< SDK_MAX_CUSTOM_HEADERS {
                let header = buffer[Int(i)]
                if let name = header.key, let value = header.value {
                    headers[String(cString: name)] = String(cString: value)
                }
            }
        }

        let payload: [String: Any] = [
            "callType": callParam.call_type,
            "username": String(cString: callParam.username),
            "remoteIp": String(cString: callParam.remote_ip),
            "headers": headers,
            "callUUID": "\(callParam.call_uuid)", // 转成 String
            "transmitVideo": callParam.transmit_video,
            "transmitSound": callParam.transmit_sound,
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onIncomingCall", arguments: payload)
    }

    static let onDtmfInfo: OnDtmfInfo = { dtmfInfoParam in
        print("DTMF info: \(dtmfInfoParam)")
        // 注册状态改变
        var contentType: String?
        if let content_type = dtmfInfoParam.content_type {
            contentType = String(cString: content_type)
        }
        var content: String?
        if let c = dtmfInfoParam.content {
            content = String(cString: c)
        }
        let payload: [String: Any] = [
            "callUUID": "\(dtmfInfoParam.call_uuid)",
            "dtmfInfoType": dtmfInfoParam.dtmf_info_type,
            "contentType": contentType ?? "",
            "content": content ?? "",
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onDtmfInfo", arguments: payload)
    }

    static let onMessage: OnMessage = { messageParam in
        print("Received message: \(messageParam)")
        var username: String?
        if let u = messageParam.username {
            username = String(cString: u)
        }
        var remoteIp: String?
        if let ip = messageParam.remote_ip {
            remoteIp = String(cString: ip)
        }
        var content: String?
        if let c = messageParam.content {
            content = String(cString: c)
        }
        let payload: [String: Any] = [
            "messageType": messageParam.message_type,
            "username": username ?? "",
            "remoteIp": remoteIp ?? "",
            "content": content ?? "",
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onMessage", arguments: payload)
    }

    static let onMessageState: OnMessageState = { state, messageParam in
        print("Message state: \(state), \(messageParam)")
        var username: String?
        if let u = messageParam.username {
            username = String(cString: u)
        }
        var remoteIp: String?
        if let ip = messageParam.remote_ip {
            remoteIp = String(cString: ip)
        }
        var content: String?
        if let c = messageParam.content {
            content = String(cString: c)
        }
        let payload: [String: Any] = [
            "state": state,
            "message": [
                "messageType": messageParam.message_type,
                "username": username ?? "",
                "remoteIp": remoteIp ?? "",
                "content": content ?? "",
            ],
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onMessageState", arguments: payload)
    }

    static let onCallState: OnCallState = { callUUID, state in
        print("Call state changed. UUID: \(callUUID), State: \(state)")
        // 呼叫连接，开启声音
        if state == CALL_STATE_CONFIRMED.rawValue {
            PCMPlayer.instance.addConsumer(uuid: callUUID)
            PCMRecorder.instance.addConsumer(uuid: callUUID)
        } else if state == CALL_STATE_DISCONNECTED.rawValue {
            PCMPlayer.instance.removeConsumer(uuid: callUUID)
            PCMRecorder.instance.removeConsumer(uuid: callUUID)
        }
        // 呼叫状态改变
        NotificationCenter.default.post(
            name: .SIP_CALL_STATE_CHANGE,
            object: nil,
            userInfo: ["callUUID": callUUID, "state": state]
        )

        let payload: [String: Any] = [
            "callUUID": "\(callUUID)",
            "state": state,
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onCallState", arguments: payload)
    }

    static let onExpireWarning: ExpireWarningCallback = { expireTime, currentTime in
        let dateFormatter = ISO8601DateFormatter()
        let expireDate = Date(timeIntervalSince1970: TimeInterval(expireTime))
        let currentDate = Date(timeIntervalSince1970: TimeInterval(currentTime))

        let payload: [String: Any] = [
            "expireTime": dateFormatter.string(from: expireDate),
            "currentTime": dateFormatter.string(from: currentDate),
        ]
        SipSdkFlutterPlugin.channel?.invokeMethod("onExpireWarning", arguments: payload)
    }
}
