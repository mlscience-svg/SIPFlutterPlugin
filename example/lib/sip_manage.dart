import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_call_param.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_camera_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_dtmf_info.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_local_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_media_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_message.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_registrar_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_stun_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_turn_config.dart';
import 'package:sip_sdk_flutter/sip_sdk_callbacks.dart';
import 'package:sip_sdk_flutter/sip_sdk_flutter.dart';

import 'call_page.dart';
import 'config_storage.dart';
import 'main.dart';

typedef OnCallState = void Function(String callUUID, int state);
typedef OnRegistrarState = void Function(int state);
typedef OnCameraStateChange = void Function(bool state);

class SIPListener {
  final OnCallState? onCallState;
  final OnRegistrarState? onRegistrarState;
  final OnCameraStateChange? onCameraStateChange;

  const SIPListener({
    this.onCallState,
    this.onRegistrarState,
    this.onCameraStateChange,
  });
}

abstract class MyListener {
  void onEvent(String data); // 抽象方法，相当于接口方法
  void onError(int code); // 可以定义多个
}

class SIPManage implements SIPSDKCallbacks {
  // 私有构造函数
  SIPManage._internal();

  // 静态私有实例
  static final SIPManage _instance = SIPManage._internal();

  // 工厂构造函数返回单例
  factory SIPManage() => _instance;

  static late SipSdkFlutter _sipSdkFlutterPlugin;

  final List<SIPListener> _listeners = [];

  static void initialize() {
    //初始化插件
    _sipSdkFlutterPlugin = SipSdkFlutter();
    //设置回调
    _sipSdkFlutterPlugin.setupCallbacks(_instance);
    //初始化SDK
    initSDK();
  }

  void addListener(SIPListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(SIPListener listener) {
    _listeners.remove(listener);
  }

  // 你可以继续在这里写你自己的方法：
  static void initSDK() async {
    Map<String, dynamic>? sconfig =
        await ConfigStorage.load(ConfigStorage.stun_config);
    STUNConfig? stunConfig;
    if (sconfig != null && (sconfig["enable"] as bool)) {
      String server = sconfig["server"] as String;
      bool enableIPv6 = sconfig["enableIPv6"] as bool;
      stunConfig = STUNConfig(servers: [server], enableIPv6: enableIPv6);
    }
    final config = SIPSDKConfig(
      baseUrl: "https://api.mlscience.cn",
      clientId: "1379018005584941056",
      clientSecret: "7489ed9e086e12ab45688c0caf4a7d2b",
      userAgent: 'flutter-1.0',
      mediaConfig: SIPSDKMediaConfig(),
      stunConfig: stunConfig,
    );
    _sipSdkFlutterPlugin.initSDK(config);
  }

  static void registrar() async {
    Map<String, dynamic>? sconfig = await ConfigStorage.load(ConfigStorage.sip_config);
    if (sconfig == null) {
      return;
    }
    Map<String, dynamic>? tconfig = await ConfigStorage.load(ConfigStorage.turn_config);
    SIPSDKTURNConfig? turnConfig;
    if (tconfig != null && (tconfig["enable"] as bool)) {
      turnConfig = SIPSDKTURNConfig(
        enable: tconfig["enable"] as bool,
        server: tconfig["server"] as String,
        realm: tconfig["realm"] as String,
        username: tconfig["username"] as String,
        password: tconfig["password"] as String,
      );
    }
    final config = SIPSDKRegistrarConfig(
      domain: sconfig["domain"] as String,
      username: sconfig["username"] as String,
      password: sconfig["password"] as String,
      transport: "tcp",
      serverAddr: sconfig["serverAddr"] as String,
      serverPort: sconfig["serverPort"] as int,
      proxy: sconfig["proxy"] as String,
      proxyPort: sconfig["proxyPort"] as int,
      enableStreamControl: false,
      streamElapsed: 0,
      startKeyframeCount: 120,
      startKeyframeInterval: 1000,
      headers: {"test": "11ddd"},
      turnConfig: turnConfig,
      localConfig: SIPSDKLocalConfig(
        username: sconfig["username"] as String,
        enableStreamControl: false,
        streamElapsed: 0,
        startKeyframeCount: 120,
        startKeyframeInterval: 1000,
      ),
    );
    _sipSdkFlutterPlugin.registrar(config);
  }

  void unRegistrar() {
    _sipSdkFlutterPlugin.unRegistrar();
  }

  Future<void> cameraOpen(SIPSDKCameraConfig config) async {
    _sipSdkFlutterPlugin.cameraOpen(config);
  }

  void cameraClose() {
    _sipSdkFlutterPlugin.cameraClose();
  }

  Future<String?> call(String username, Map<String, String> headers) {
    return _sipSdkFlutterPlugin.call(username, headers);
  }

  Future<String?> callIP(String ip, Map<String, String> headers) {
    return _sipSdkFlutterPlugin.callIP(ip, headers);
  }

  // 通常情况不用调用接听，因为被叫界面是原生代码
  void answer(int code, [String? callUUID]) {
    _sipSdkFlutterPlugin.answer(code, callUUID);
  }

  // 通常情况不用调用发送Dtmf Info，因为被叫界面是原生代码
  void sendDtmfInfo(int type, String content, String callUUID) {
    _sipSdkFlutterPlugin.sendDtmfInfo(type, content, callUUID);
  }

  // 通常情况不用调用挂断，因为被叫界面是原生代码
  void hangup(int code, [String? callUUID]) {
    _sipSdkFlutterPlugin.hangup(code, callUUID);
  }

  void sendMessage(String username, String content) {
    _sipSdkFlutterPlugin.sendMessage(username, content);
  }

  void sendMessageIP(String username, String content) {
    _sipSdkFlutterPlugin.sendMessageIP(username, content);
  }

  // 通常情况不用调用dump，这个主要用于调试
  void dump() {
    _sipSdkFlutterPlugin.dump();
  }

  Future<bool?> isMute() {
    return _sipSdkFlutterPlugin.isMute();
  }

  void setMute(bool mute) {
    _sipSdkFlutterPlugin.setMute(mute);
  }

  Future<bool?> isSpeaker() {
    return _sipSdkFlutterPlugin.isSpeaker();
  }

  void setSpeaker(bool speaker) {
    _sipSdkFlutterPlugin.setSpeaker(speaker);
  }

  @override
  void onInitCompleted(int state, String message) {
    debugPrint("onInitCompleted: $state    $message");
  }

  @override
  void onStopCompleted() {
    debugPrint("onStopCompleted");
  }

  @override
  void onRegistrarState(int state) {
    debugPrint("onRegistrarState: $state");
    for (final listener in List<SIPListener>.from(_listeners)) {
      listener.onRegistrarState?.call(state);
    }
  }

  @override
  void onDtmfInfo(SIPSDKDtmfInfo dtmfInfo) {
    debugPrint("onDtmfInfo: ${dtmfInfo.toString()}");
  }

  @override
  void onMessage(SIPSDKMessage message) {
    debugPrint("onMessage: ${message.toString()}");
  }

  @override
  void onMessageState(int state, SIPSDKMessage message) {
    debugPrint("onMessages: $state:${message.toString()}");
  }

  @override
  void onCallState(String callUUID, int state) {
    for (final listener in List<SIPListener>.from(_listeners)) {
      listener.onCallState?.call(callUUID, state);
    }
  }

  @override
  void onIncomingCall(SIPSDKCallParam callParam) {
    debugPrint("onIncomingCall: ${callParam.toString()}");
    BuildContext? context = navigatorKey.currentState?.overlay?.context;
    //收到呼叫
    Navigator.of(context!).push(
      MaterialPageRoute(builder: (_) {
        int direction = 1; //0.主动呼叫 1.被叫
        return CallPage(
          direction: direction,
          callType: callParam.callType,
          callUUID: callParam.callUUID,
          username: callParam.username,
          remoteIp: callParam.remoteIp,
          headers: callParam.headers,
        );
      }),
    );
  }

  @override
  void onExpireWarning(DateTime expireTime, DateTime currentTime) {
    final expireStr = expireTime.toLocal().toString();
    final currentStr = currentTime.toLocal().toString();
    debugPrint(
      'License will expire at: $expireStr, current time is: $currentStr',
    );
  }

  @override
  void onCameraStateChange(bool state) {
    for (final listener in List<SIPListener>.from(_listeners)) {
      listener.onCameraStateChange?.call(state);
    }
  }
}
