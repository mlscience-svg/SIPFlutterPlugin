import sip_callback, { SIPListener } from "sipsdkapi/src/main/ets/sip/SIPCallback";
import { AppStorageV2, UIContext } from "@kit.ArkUI";
import { SIPHandle } from "sipsdkapi/src/main/ets/sip/SIPHandle";
import {
  SIPCallParam,
  SIPLocalConfig,
  SIPRegistrarConfig,
  SIPSDKCameraConfig
} from "sipsdkapi/src/main/ets/entity/SIPEntity";
import { Any } from '@ohos/flutter_ohos';
import { SIPMediaListener, SIPSDKConfig, SIPSDKMediaConfig } from "sipsdkapi";
import SipSdkFlutterPlugin from "../plugin/SipSdkFlutterPlugin";
import { SIPDtmfInfoParam } from "sipsdkapi/Index";
import { SIPMessageParam } from "sipsdkapi/Index";
import { SIPAnswerParam } from "sipsdkapi/Index";

export class SIPManager {
  static listener: SIPListener = {
    onInitCompleted: (state: number, msg: string) => {
      let map: Map<Any, Any> = new Map();
      map.set("state", state);
      map.set("message", msg);
      SipSdkFlutterPlugin.channel?.invokeMethod("onInitCompleted", map);
    },
    onStopCompleted: () => {
      SipSdkFlutterPlugin.channel?.invokeMethod("onStopCompleted", null);
    },
    onRegistryState: (code: number) => {
      let map: Map<Any, Any> = new Map();
      map.set("state", code);
      SipSdkFlutterPlugin.channel?.invokeMethod("onRegistrarState", map);
    },
    onIncomingCall: (param: SIPCallParam) => {
      let map: Map<Any, Any> = new Map();
      map.set("callType", param.callType);
      map.set("callUUID", param.callUuid?.toString());
      map.set("username", param.username);
      map.set("remoteIp", param.remoteIp);
      map.set("transmitVideo", param.transmitVideo);
      map.set("transmitSound", param.transmitSound);
      map.set("headers", param.headers);
      SipSdkFlutterPlugin.channel?.invokeMethod("onIncomingCall", map);
    },
    onCallState: (callUuid: bigint, state: number) => {
      let map: Map<Any, Any> = new Map();
      map.set("callUUID", callUuid.toString());
      map.set("state", state);
      SipSdkFlutterPlugin.channel?.invokeMethod("onCallState", map);
    },
    onDtmfInfo: (param: SIPDtmfInfoParam) => {
      let map: Map<Any, Any> = new Map();
      map.set("callUUID", param.callUuid?.toString());
      map.set("dtmfInfoType", param.dtmfInfoType);
      map.set("contentType", param.contentType);
      map.set("content", param.content);
      SipSdkFlutterPlugin.channel?.invokeMethod("onDtmfInfo", map);
    },
    onMessage: (param: SIPMessageParam) => {
      let map: Map<Any, Any> = new Map();
      map.set("messageType", param.messageType);
      map.set("username", param.username);
      map.set("remoteIp", param.remoteIp);
      map.set("content", param.content);
      SipSdkFlutterPlugin.channel?.invokeMethod("onMessage", map);
    },
    onMessageState: (state: number, param: SIPMessageParam) => {
      let map: Map<Any, Any> = new Map();
      map.set("state", state);
      let message: Map<Any, Any> = new Map();
      message.set("messageType", param.messageType);
      message.set("username", param.username);
      message.set("remoteIp", param.remoteIp);
      message.set("content", param.content);
      map.set("message", message);
      SipSdkFlutterPlugin.channel?.invokeMethod("onMessage", map);
    },
    onExpireWarning: (expireTime: number, currentTime: number) => {
      let map: Map<Any, Any> = new Map();
      map.set("expireTime", expireTime);
      map.set("currentTime", currentTime);
      SipSdkFlutterPlugin.channel?.invokeMethod("onExpireWarning", map);
    }
  };
  static mediaListener: SIPMediaListener = {
    onCameraStateChange: (state: boolean) => {
      let map: Map<Any, Any> = new Map();
      map.set("state", state);
      SipSdkFlutterPlugin.channel?.invokeMethod("onCameraStateChange", map);
    },
  }

  static async init(
    baseUrl: string,
    clientId: string,
    clientSecret: string,
    config: SIPSDKConfig,
    mediaConfig?: SIPSDKMediaConfig) {
    //注册回调
    sip_callback.addListener(SIPManager.listener);
    //注册媒体回调
    sip_callback.addMediaListener(SIPManager.mediaListener);
    //初始化SDK
    const context = AppStorageV2.connect(UIContext, 'uiContext', () => new UIContext())?.getHostContext();
    SIPHandle.init(context!, baseUrl, clientId, clientSecret, config, mediaConfig);
  }

  static registrar(localConfig: SIPLocalConfig, registrarConfig: SIPRegistrarConfig) {
    SIPHandle.localAccount(localConfig);
    SIPHandle.remotelAccount(registrarConfig);
  }

  static unRegistrar() {
    SIPHandle.delRemotelAccount();
  }

  static async cameraOpen(param: SIPSDKCameraConfig): Promise<boolean> {
    return SIPHandle.cameraOpen(param)
  }

  static cameraClose() {
    SIPHandle.cameraClose()
  }

  static async makeCall(param: SIPCallParam): Promise<bigint> {
    return SIPHandle.makeCall(param)
  }

  static async answer(param: SIPAnswerParam): Promise<void> {
    SIPHandle.answer(param)
  }

  static async hangup(code: number, callUuid?: bigint): Promise<void> {
    SIPHandle.hangup(code, callUuid)
  }

  static async dtmfInfo(param: SIPDtmfInfoParam): Promise<void> {
    SIPHandle.dtmfInfo(param)
  }

  static async sendMessage(param: SIPMessageParam): Promise<void> {
    SIPHandle.sendMessage(param)
  }

  static async dump(): Promise<void> {
    SIPHandle.dump()
  }

  static async destroy(): Promise<void> {
    SIPHandle.destroy()
  }

  static async handleIpChange(): Promise<void> {
    SIPHandle.handleIpChange()
  }
}