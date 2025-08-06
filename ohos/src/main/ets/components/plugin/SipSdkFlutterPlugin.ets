import {
  Any,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StandardMessageCodec,
  ToolUtils,
} from '@ohos/flutter_ohos';
import { isSpeaker, setSpeaker, isMute, setMute } from 'sipsdkapi';
import { VideoComponentFactory } from '../pages/VideoComponentFactory';
import { SIPManager } from '../sip/SIPManager';

/** SipSdkFlutterPlugin **/
export default class SipSdkFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  public static channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "SipSdkFlutterPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    SipSdkFlutterPlugin.channel = new MethodChannel(binding.getBinaryMessenger(), "sip_sdk_flutter");
    SipSdkFlutterPlugin.channel.setMethodCallHandler(this)
    binding.getPlatformViewRegistry()?.
    registerViewFactory('com.sip.flutter/VideoComponentView',
      new VideoComponentFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE));
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (SipSdkFlutterPlugin.channel != null) {
      SipSdkFlutterPlugin.channel.setMethodCallHandler(null)
    }
  }

  printDetails(tag: string, args: Any): void {
    if (args instanceof Map) {
      (args as Map<Any, Any>).forEach((value: Any, key: Any) => {
        console.error(tag, "Arguments as Map:", key, value);
      });
    } else if (ToolUtils.isObj(args)) {
      console.error(tag, "Arguments as Object:", JSON.stringify(args, null, 2));
    } else {
      console.error(tag, "Arguments (Raw):", args);
    }
  }

  // Map 转 Record
  mapToRecord(map: Map<string, string>): Record<string, string> {
    const obj: Record<string, string> = {};
    map.forEach((value, key) => {
      obj[key] = value;
    });
    return obj;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === "initSDK") {
      this.initSDK(call, result);
      result.success(null);
    } else if (call.method === "registrar") {
      this.registrar(call, result);
    } else if (call.method == "unRegistrar") {
      this.unRegistrar(call, result);
    } else if (call.method == "cameraOpen") {
      this.cameraOpen(call, result);
    } else if (call.method == "cameraClose") {
      this.cameraClose(call, result);
    } else if (call.method == "call") {
      this.call(call, result);
    } else if (call.method == "callIP") {
      this.callIP(call, result);
    } else if (call.method == "answer") {
      this.answer(call, result);
    } else if (call.method == "sendDtmfInfo") {
      this.sendDtmfInfo(call, result);
    } else if (call.method == "sendMessage") {
      this.sendMessage(call, result);
    } else if (call.method == "sendMessageIP") {
      this.sendMessageIP(call, result);
    } else if (call.method == "hangup") {
      this.hangup(call, result);
    } else if (call.method == "dump") {
      this.dump(call, result);
    } else if (call.method == "destroy") {
      this.destroy(call, result);
    } else if (call.method == "handleIpChange") {
      this.handleIpChange(call, result);
    } else if (call.method == "isMute") {
      this.isMute(call, result);
    } else if (call.method == "setMute") {
      this.setMute(call, result);
    } else if (call.method == "isSpeaker") {
      this.isSpeaker(call, result);
    } else if (call.method == "setSpeaker") {
      this.setSpeaker(call, result);
    } else {
      result.notImplemented()
    }
  }

  initSDK(call: MethodCall, result: MethodResult) {
    let baseUrl: string = call.argument("baseUrl");
    let clientId: string = call.argument("clientId");
    let clientSecret: string = call.argument("clientSecret");
    //基础配置

    let port: number = call.argument("port");
    let publicAddr: string = call.argument("publicAddr");
    let logLevel: number = call.argument("logLevel");


    let userAgent: string = call.argument("userAgent");
    let workerThreadCount: number = call.argument("workerThreadCount");
    let enableVideo: boolean = call.argument("enableVideo");
    let videoOutAutoTransmit: boolean = call.argument("videoOutAutoTransmit");
    let allowMultipleConnections: boolean = call.argument("allowMultipleConnections");
    let domainNameDirectRegistrar: boolean = call.argument("domainNameDirectRegistrar");
    let doesItSupportBroadcast: boolean = call.argument("doesItSupportBroadcast");
    //stun 配置
    let stunConfig: Map<Any, Any> = call.argument("stunConfig");
    this.printDetails("stunConfig", stunConfig);

    //媒体配置
    let mediaConfig: Map<Any, Any> = call.argument("mediaConfig");
    this.printDetails("mediaConfig", mediaConfig);

    // H264 Fmtp
    let h264Fmtp: Map<Any, Any> = mediaConfig.get("h264Fmtp");
    this.printDetails("h264Fmtp", h264Fmtp);

    //Decode Config
    let decodeConfig: Map<Any, Any> = mediaConfig.get("decodeConfig");
    this.printDetails("decodeConfig", decodeConfig);

    //Encode Config
    let encodeConfig: Map<Any, Any> = mediaConfig.get("encodeConfig");
    this.printDetails("encodeConfig", encodeConfig);

    SIPManager.init(baseUrl, clientId, clientSecret, {
      port: port,
      logLevel: logLevel,
      userAgent: userAgent,
      publicAddr: publicAddr,
      videoEnable: enableVideo,
      workerThreadCount: workerThreadCount,
      transportStunServer: false,
      videoOutAutoTransmit: videoOutAutoTransmit,
      doesItSupportBroadcast: doesItSupportBroadcast,
      allowMultipleConnections: allowMultipleConnections,
      domainNameDirectRegistrar: domainNameDirectRegistrar,
      sipSdkStunConfig: stunConfig ? {
        count: (stunConfig.get("servers") as string[]).length,
        servers: stunConfig.get("servers"),
        enableIpv6: stunConfig.get("enableIpv6"),
      } : undefined,
    }, mediaConfig ? {
      audioClockRate: mediaConfig.get("audioClockRate"),
      micGain: mediaConfig.get("micGain"),
      speakerGain: mediaConfig.get("speakerGain"),
      nsEnable: mediaConfig.get("nsEnable"),
      agcEnable: mediaConfig.get("agcEnable"),
      aecEnable: mediaConfig.get("aecEnable"),
      aecEliminationTime: mediaConfig.get("aecEliminationTime"),
      h264Fmtp: h264Fmtp ? {
        profileLevelId: h264Fmtp.get("profileLevelId"),
        packetizationMode: h264Fmtp.get("packetizationMode"),
      } : undefined,
      decodeConfig: decodeConfig ? {
        enable: decodeConfig.get("enable"),
        maxWidth: decodeConfig.get("maxWidth"),
        maxHeight: decodeConfig.get("maxHeight"),
        combinSpsPpsIdr: decodeConfig.get("combinSpsPpsIdr"),
      } : undefined,
      encodeConfig: encodeConfig ? {
        enable: encodeConfig.get("enable"),
        width: encodeConfig.get("width"),
        height: encodeConfig.get("height"),
        fps: encodeConfig.get("fps"),
        bps: encodeConfig.get("bps"),
        minBps: encodeConfig.get("minBps"),
        maxBps: encodeConfig.get("maxBps"),
        rcMode: encodeConfig.get("rcMode"),
        frameSkip: encodeConfig.get("frameSkip"),
        qp: encodeConfig.get("qp"),
      } : undefined,
    } : undefined);
    result.success(null);
  }

  registrar(call: MethodCall, result: MethodResult) {
    this.printDetails("registrar", call.args);
    let domain: string = call.argument("domain");
    let username: string = call.argument("username");
    let password: string = call.argument("password");
    let transport: string = call.argument("transport");
    let serverAddr: string = call.argument("serverAddr");
    let serverPort: number = call.argument("serverPort");
    let headers: Map<string, string> = call.argument("headers");
    let proxy: string = call.argument("proxy");
    let proxyPort: number = call.argument("proxyPort");
    let enableStreamControl: boolean = call.argument("enableStreamControl");
    let streamElapsed: number = call.argument("streamElapsed");
    let startKeyframeCount: number = call.argument("startKeyframeCount");
    let startKeyframeInterval: number = call.argument("startKeyframeInterval");

    // Turn Config
    let turnConfig: Map<Any, Any> = call.argument("turnConfig");
    this.printDetails("turnConfig", turnConfig);

    //Local Config
    let localConfig: Map<Any, Any> = call.argument("localConfig");
    this.printDetails("localConfig", localConfig);

    SIPManager.registrar({
      username: localConfig.get("username"),
      proxy: localConfig.get("proxy"),
      proxyPort: localConfig.get("proxyPort"),
      enableStreamControl: localConfig.get("enableStreamControl"),
      streamElapsed: localConfig.get("streamElapsed"),
      startKeyframeCount: localConfig.get("startKeyframeCount"),
      startKeyframeInterval: localConfig.get("startKeyframeInterval"),
    }, {
      domain: domain,
      username: username,
      password: password,
      transport: transport,
      serverAddr: serverAddr,
      serverPort: serverPort,
      headers: headers ? this.mapToRecord(headers) : {},
      proxy: proxy,
      proxyPort: proxyPort,
      enableStreamControl: enableStreamControl,
      streamElapsed: streamElapsed,
      startKeyframeCount: startKeyframeCount,
      startKeyframeInterval: startKeyframeInterval,
      turnConfig: turnConfig ? {
        enable: turnConfig.get("enable"),
        server: turnConfig.get("server"),
        realm: turnConfig.get("realm"),
        username: turnConfig.get("username"),
        password: turnConfig.get("password"),
      } : undefined,
    });
    result.success(null);
  }

  unRegistrar(call: MethodCall, result: MethodResult) {
    this.printDetails("unRegistrar", call.args);
    SIPManager.unRegistrar();
    result.success(null);
  }

  async cameraOpen(call: MethodCall, result: MethodResult) {
    this.printDetails("cameraOpen", call.args);
    SIPManager.cameraOpen({
      index: call.argument("index"),
      width: call.hasArgument("width") ? call.argument("width") : 640,
      height: call.hasArgument("height") ? call.argument("height") : 480,
      rotate: call.hasArgument("rotate") ? call.argument("rotate") : undefined,
    });
    result.success(null);
  }

  async cameraClose(call: MethodCall, result: MethodResult) {
    this.printDetails("cameraOpen", call.args);
    SIPManager.cameraClose();
    result.success(null);
  }

  async call(call: MethodCall, result: MethodResult) {
    this.printDetails("call", call.args);
    let username: string = call.argument("username");
    let headers: Map<string, string> = call.argument("headers");
    let callUuid = await SIPManager.makeCall({
      callType: 1,
      username: username,
      headers: headers ? this.mapToRecord(headers) : {},
    });
    result.success(callUuid.toString());
  }

  async callIP(call: MethodCall, result: MethodResult) {
    this.printDetails("call", call.args);
    let remoteIp: string = call.argument("remoteIp");
    let headers: Map<string, string> = call.argument("headers");
    let callUuid = await SIPManager.makeCall({
      callType: 0,
      remoteIp: remoteIp,
      headers: headers ? this.mapToRecord(headers) : {},
    });
    result.success(callUuid.toString());
  }

  async answer(call: MethodCall, result: MethodResult) {
    this.printDetails("answer", call.args);
    SIPManager.answer({
      code: call.argument("code"),
      callUuid: call.argument("callUUID"),
      video: call.argument("video"),
      sound: call.argument("sound"),
    });
    result.success(null);
  }

  async hangup(call: MethodCall, result: MethodResult) {
    this.printDetails("hangup", call.args);
    let code: number = call.argument("code");
    let callUUID: bigint = call.argument("callUUID");
    SIPManager.hangup(code, callUUID);
    result.success(null);
  }

  async sendDtmfInfo(call: MethodCall, result: MethodResult) {
    this.printDetails("sendDtmfInfo", call.args);
    SIPManager.dtmfInfo({
      dtmfInfoType: call.argument("dtmfInfoType"),
      callUuid: call.argument("callUUID"),
      contentType: call.argument("contentType"),
      content: call.argument("content"),
    });
    result.success(null);
  }

  async sendMessage(call: MethodCall, result: MethodResult) {
    this.printDetails("sendMessage", call.args);
    SIPManager.sendMessage({
      messageType: 1,
      username: call.argument("username"),
      content: call.argument("content"),
    });
    result.success(null);
  }

  async sendMessageIP(call: MethodCall, result: MethodResult) {
    this.printDetails("sendMessage", call.args);
    SIPManager.sendMessage({
      messageType: 0,
      remoteIp: call.argument("remoteIp"),
      content: call.argument("content"),
    });
    result.success(null);
  }

  async dump(call: MethodCall, result: MethodResult) {
    this.printDetails("dump", call.args);
    SIPManager.dump();
    result.success(null);
  }

  async destroy(call: MethodCall, result: MethodResult) {
    this.printDetails("destroy", call.args);
    SIPManager.destroy();
    result.success(null);
  }

  async handleIpChange(call: MethodCall, result: MethodResult) {
    this.printDetails("handleIpChange", call.args);
    SIPManager.handleIpChange();
    result.success(null);
  }

  async isMute(call: MethodCall, result: MethodResult) {
    this.printDetails("isMute", call.args);
    let ret: boolean = await isMute();
    result.success(ret);
  }

  async setMute(call: MethodCall, result: MethodResult) {
    this.printDetails("setMute", call.args);
    let mute: boolean = call.argument("mute");
    setMute(mute);
    result.success(null);
  }

  async isSpeaker(call: MethodCall, result: MethodResult) {
    this.printDetails("getAudioOutputDevice", call.args);
    let speaker: boolean = await isSpeaker();
    result.success(speaker);
  }

  async setSpeaker(call: MethodCall, result: MethodResult) {
    this.printDetails("setAudioOutputDevice", call.args);
    let speaker: boolean = call.argument("speaker");
    setSpeaker(speaker);
    result.success(null);
  }
}