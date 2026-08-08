import 'dart:ffi';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_local_config.dart';
import 'dart:typed_data';

import 'entitys/sip_sdk_camera_config.dart';
import 'entitys/sip_sdk_config.dart';
import 'entitys/sip_sdk_registrar_config.dart';
import 'sip_sdk_flutter_method_channel.dart';
import 'package:sip_sdk_flutter/sip_sdk_callbacks.dart';

abstract class SipSdkFlutterPlatform extends PlatformInterface {
  /// Constructs a SipSdkFlutterPlatform.
  SipSdkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static SipSdkFlutterPlatform _instance = MethodChannelSipSdkFlutter();

  /// The default instance of [SipSdkFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelSipSdkFlutter].
  static SipSdkFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SipSdkFlutterPlatform] when
  /// they register themselves.
  static set instance(SipSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Void?> setupCallbacks(SIPSDKCallbacks callbacks) {
    throw UnimplementedError('setupCallbacks() has not been implemented.');
  }

  Future<Void?> initSDK(SIPSDKConfig config) {
    throw UnimplementedError('initSDK() has not been implemented.');
  }

  Future<Void?> initToken(SIPSDKConfig config) {
    throw UnimplementedError('initToken() has not been implemented.');
  }

  Future<Void?> localAccount(SIPSDKLocalConfig config) {
    throw UnimplementedError('localAccount() has not been implemented.');
  }

  Future<Void?> remoteAccount(SIPSDKRegistrarConfig config) {
    throw UnimplementedError('remoteAccount() has not been implemented.');
  }

  Future<void> delRemoteAccount() {
    throw UnimplementedError('delRemoteAccount() has not been implemented.');
  }

  Future<void> cameraOpen(SIPSDKCameraConfig config) {
    throw UnimplementedError('cameraOpen() has not been implemented.');
  }

  Future<void> cameraClose() {
    throw UnimplementedError('cameraClose() has not been implemented.');
  }

  Future<Uint8List?> captureSnapshot() {
    throw UnimplementedError('captureSnapshot() has not been implemented.');
  }

  /// 截取对方视频画面并保存为 JPG 到外部存储
  /// `Documents/Doorbell/<deviceName>/`，返回保存路径。
  Future<String?> captureSnapshotToDocuments(String deviceName) {
    throw UnimplementedError(
      'captureSnapshotToDocuments() has not been implemented.',
    );
  }

  Future<String?> startVideoRecording(String deviceName) {
    throw UnimplementedError(
      'startVideoRecording() has not been implemented.',
    );
  }

  Future<String?> stopVideoRecording() {
    throw UnimplementedError(
      'stopVideoRecording() has not been implemented.',
    );
  }

  Future<String?> call(
    int type, {
    String? username,
    String? remoteIp,
    bool? transmitVideo,
    bool? transmitSound,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError('call() has not been implemented.');
  }

  Future<void> answer(int code, [String? callUuid]) {
    throw UnimplementedError('answer() has not been implemented.');
  }

  Future<void> sendDtmfInfo(int type, String content, String callUuid) {
    throw UnimplementedError('sendDtmfInfo() has not been implemented.');
  }

  Future<void> sendMessage(
    int type,
    String content, {
    String? username,
    String? remoteIp,
  }) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  Future<void> hangup(int code, [String? callUuid]) {
    throw UnimplementedError('hangup() has not been implemented.');
  }

  Future<void> dump() {
    throw UnimplementedError('dump() has not been implemented.');
  }

  Future<void> handleIpChange() {
    throw UnimplementedError('dump() has not been implemented.');
  }

  Future<void> destroy() {
    throw UnimplementedError('destroy() has not been implemented.');
  }

  Future<void> startRecording([int? sampleRate]) {
    throw UnimplementedError('startRecording() has not been implemented.');
  }

  Future<void> stopRecording() {
    throw UnimplementedError('stopRecording() has not been implemented.');
  }

  Future<void> startPlaying([int? sampleRate]) {
    throw UnimplementedError('startPlaying() has not been implemented.');
  }

  Future<void> stopPlaying() {
    throw UnimplementedError('stopPlaying() has not been implemented.');
  }

  Future<bool?> isMute() {
    throw UnimplementedError('isMute() has not been implemented.');
  }

  Future<void> setMute(bool mute) {
    throw UnimplementedError('setMute() has not been implemented.');
  }

  Future<bool?> isSpeaker() {
    throw UnimplementedError('isSpeaker() has not been implemented.');
  }

  Future<void> setSpeaker(bool speaker) {
    throw UnimplementedError('setSpeaker() has not been implemented.');
  }
}
