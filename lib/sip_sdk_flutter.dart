import 'dart:ffi';

import 'package:sip_sdk_flutter/sip_sdk_callbacks.dart';

import 'entitys/sip_sdk_camera_config.dart';
import 'entitys/sip_sdk_config.dart';
import 'entitys/sip_sdk_registrar_config.dart';
import 'sip_sdk_flutter_platform_interface.dart';

class SipSdkFlutter {
  Future<Void?> setupCallbacks(SIPSDKCallbacks callbacks) {
    return SipSdkFlutterPlatform.instance.setupCallbacks(callbacks);
  }

  Future<Void?> initSDK(SIPSDKConfig config) {
    return SipSdkFlutterPlatform.instance.initSDK(config);
  }

  Future<Void?> registrar(SIPSDKRegistrarConfig config) {
    return SipSdkFlutterPlatform.instance.registrar(config);
  }

  Future<void> unRegistrar() {
    return SipSdkFlutterPlatform.instance.unRegistrar();
  }

  Future<void> cameraOpen(SIPSDKCameraConfig config) {
    return SipSdkFlutterPlatform.instance.cameraOpen(config);
  }

  Future<void> cameraClose() {
    return SipSdkFlutterPlatform.instance.cameraClose();
  }

  Future<String?> call(String username, Map<String, String> headers) {
    return SipSdkFlutterPlatform.instance.call(username, headers);
  }

  Future<String?> callIP(String ip, Map<String, String> headers) {
    return SipSdkFlutterPlatform.instance.callIP(ip, headers);
  }

  Future<void> answer(int code, [String? callUUID]) {
    return SipSdkFlutterPlatform.instance.answer(code, callUUID);
  }

  Future<void> sendDtmfInfo(int type, String content, String callUUID) {
    return SipSdkFlutterPlatform.instance.sendDtmfInfo(type, content, callUUID);
  }

  Future<void> sendMessage(String username, String content) {
    return SipSdkFlutterPlatform.instance.sendMessage(username, content);
  }

  Future<void> sendMessageIP(String ip, String content) {
    return SipSdkFlutterPlatform.instance.sendMessageIP(ip, content);
  }

  Future<void> hangup(int code, [String? callUUID]) {
    return SipSdkFlutterPlatform.instance.hangup(code, callUUID);
  }

  Future<void> dump() {
    return SipSdkFlutterPlatform.instance.dump();
  }

  Future<void> handleIpChange() {
    return SipSdkFlutterPlatform.instance.handleIpChange();
  }

  Future<void> destroy() {
    return SipSdkFlutterPlatform.instance.destroy();
  }

  Future<bool?> isMute() {
    return SipSdkFlutterPlatform.instance.isMute();
  }

  Future<void> setMute(bool mute) {
    return SipSdkFlutterPlatform.instance.setMute(mute);
  }

  Future<bool?> isSpeaker() {
    return SipSdkFlutterPlatform.instance.isSpeaker();
  }

  Future<void> setSpeaker(bool speaker) {
    return SipSdkFlutterPlatform.instance.setSpeaker(speaker);
  }
}
