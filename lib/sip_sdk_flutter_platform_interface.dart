import 'dart:ffi';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  Future<Void?> registrar(SIPSDKRegistrarConfig config) {
    throw UnimplementedError('registrar() has not been implemented.');
  }

  Future<void> unRegistrar() {
    throw UnimplementedError('unRegistrar() has not been implemented.');
  }

  Future<void> cameraOpen(SIPSDKCameraConfig config) {
    throw UnimplementedError('cameraOpen() has not been implemented.');
  }

  Future<void> cameraClose() {
    throw UnimplementedError('cameraClose() has not been implemented.');
  }

  Future<String?> call(String username, Map<String, String> headers) {
    throw UnimplementedError('call() has not been implemented.');
  }

  Future<String?> callIP(String ip, Map<String, String> headers) {
    throw UnimplementedError('callIP() has not been implemented.');
  }

  Future<void> answer(int code, [String? callUUID]) {
    throw UnimplementedError('answer() has not been implemented.');
  }

  Future<void> sendDtmfInfo(int type, String content, String callUUID) {
    throw UnimplementedError('sendDtmfInfo() has not been implemented.');
  }

  Future<void> sendMessage(String username, String content) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  Future<void> sendMessageIP(String ip, String content) {
    throw UnimplementedError('sendMessageIP() has not been implemented.');
  }

  Future<void> hangup(int code, [String? callUUID]) {
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
