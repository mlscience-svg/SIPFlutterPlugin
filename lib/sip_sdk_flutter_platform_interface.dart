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

  /// 截取对方视频画面并保存为 JPG 到 `relativePath`（相对媒体根目录的完整路径，含文件名）。
  Future<String?> captureSnapshotToPath(String relativePath) {
    throw UnimplementedError(
      'captureSnapshotToPath() has not been implemented.',
    );
  }

  Future<String?> startVideoRecording(String relativePath) {
    throw UnimplementedError(
      'startVideoRecording() has not been implemented.',
    );
  }

  Future<String?> stopVideoRecording() {
    throw UnimplementedError(
      'stopVideoRecording() has not been implemented.',
    );
  }

  /// 查询已保存的拍照 / 录制视频文件（见 [SipSdkFlutter.queryMediaFiles]）。
  Future<List<Map<String, dynamic>>?> queryMediaFiles() {
    throw UnimplementedError('queryMediaFiles() has not been implemented.');
  }

  /// 一次性迁移旧媒体目录到 app 公共根目录（见 [SipSdkFlutter.migrateMediaToAppRoot]）。
  Future<void> migrateMediaToAppRoot() {
    throw UnimplementedError('migrateMediaToAppRoot() has not been implemented.');
  }

  /// 读取媒体条目缩略图（见 [SipSdkFlutter.loadMediaThumbnail]）。
  Future<Uint8List?> loadMediaThumbnail(String uri, int maxSize) {
    throw UnimplementedError('loadMediaThumbnail() has not been implemented.');
  }

  /// 读取媒体条目完整字节（见 [SipSdkFlutter.loadMediaBytes]）。
  Future<Uint8List?> loadMediaBytes(String uri) {
    throw UnimplementedError('loadMediaBytes() has not been implemented.');
  }

  /// 全屏播放视频（见 [SipSdkFlutter.playMediaVideo]）。
  Future<void> playMediaVideo(String uri) {
    throw UnimplementedError('playMediaVideo() has not been implemented.');
  }

  /// 保存媒体条目到系统相册（见 [SipSdkFlutter.saveMediaToAlbum]）。
  Future<bool> saveMediaToAlbum(String uri, {bool isVideo = false}) {
    throw UnimplementedError('saveMediaToAlbum() has not been implemented.');
  }

  /// 批量删除媒体条目（见 [SipSdkFlutter.deleteMediaFiles]）。
  Future<bool> deleteMediaFiles(List<String> uris) {
    throw UnimplementedError('deleteMediaFiles() has not been implemented.');
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

  Future<void> setImageRatio(bool originalRatio) {
    throw UnimplementedError('setImageRatio() has not been implemented.');
  }

  Future<void> clearVideo() {
    throw UnimplementedError('clearVideo() has not been implemented.');
  }
}
