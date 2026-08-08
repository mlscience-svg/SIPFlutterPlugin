import 'dart:ffi';
import 'dart:typed_data';

import 'package:sip_sdk_flutter/entitys/sip_sdk_local_config.dart';
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

  Future<Void?> initToken(SIPSDKConfig config) {
    return SipSdkFlutterPlatform.instance.initToken(config);
  }

  Future<Void?> localAccount(SIPSDKLocalConfig config) {
    return SipSdkFlutterPlatform.instance.localAccount(config);
  }

  Future<Void?> remoteAccount(SIPSDKRegistrarConfig config) {
    return SipSdkFlutterPlatform.instance.remoteAccount(config);
  }

  Future<void> delRemoteAccount() {
    return SipSdkFlutterPlatform.instance.delRemoteAccount();
  }

  Future<void> cameraOpen(SIPSDKCameraConfig config) {
    return SipSdkFlutterPlatform.instance.cameraOpen(config);
  }

  Future<void> cameraClose() {
    return SipSdkFlutterPlatform.instance.cameraClose();
  }

  Future<Uint8List?> captureSnapshot() {
    return SipSdkFlutterPlatform.instance.captureSnapshot();
  }

  /// 截取对方视频画面并保存为 JPG 到外部存储
  /// `Documents/Doorbell/<deviceName>/`，返回保存路径。
  Future<String?> captureSnapshotToDocuments(String deviceName) {
    return SipSdkFlutterPlatform.instance.captureSnapshotToDocuments(deviceName);
  }

  /// 开始录制通话视频。`deviceName` 用于把录制完成的视频归档到外部存储
  /// `Documents/Doorbell/<deviceName>/` 目录下，返回录制的临时路径或 null。
  Future<String?> startVideoRecording(String deviceName) {
    return SipSdkFlutterPlatform.instance.startVideoRecording(deviceName);
  }

  Future<String?> stopVideoRecording() {
    return SipSdkFlutterPlatform.instance.stopVideoRecording();
  }

  Future<String?> call(
    int type, {
    String? username,
    String? remoteIp,
    bool? transmitVideo,
    bool? transmitSound,
    Map<String, String>? headers,
  }) {
    return SipSdkFlutterPlatform.instance.call(
      type,
      username: username,
      remoteIp: remoteIp,
      transmitVideo: transmitVideo,
      transmitSound: transmitSound,
      headers: headers,
    );
  }

  Future<void> answer(int code, [String? callUuid]) {
    return SipSdkFlutterPlatform.instance.answer(code, callUuid);
  }

  Future<void> sendDtmfInfo(int type, String content, String callUuid) {
    return SipSdkFlutterPlatform.instance.sendDtmfInfo(type, content, callUuid);
  }

  Future<void> sendMessage(
    int type,
    String content, {
    String? username,
    String? remoteIp,
  }) {
    return SipSdkFlutterPlatform.instance.sendMessage(
      type,
      content,
      username: username,
      remoteIp: remoteIp,
    );
  }

  Future<void> hangup(int code, [String? callUuid]) {
    return SipSdkFlutterPlatform.instance.hangup(code, callUuid);
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

  Future<void> startRecording([int? sampleRate]) {
    return SipSdkFlutterPlatform.instance.startRecording(sampleRate);
  }

  Future<void> stopRecording() {
    return SipSdkFlutterPlatform.instance.stopRecording();
  }

  Future<void> startPlaying([int? sampleRate]) {
    return SipSdkFlutterPlatform.instance.startPlaying(sampleRate);
  }

  Future<void> stopPlaying() {
    return SipSdkFlutterPlatform.instance.stopPlaying();
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
