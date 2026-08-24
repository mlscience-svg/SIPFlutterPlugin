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

  /// 截取对方视频画面并保存为 JPG 到 `relativePath` 指定的位置。
  /// `relativePath` 是相对媒体根目录的完整路径（含文件名），如
  /// `Doorbell/<deviceId>/photo/2026/08/10/101530_123.jpg`，目录不存在会自动创建。
  /// Android 落在 `Documents/` 下，iOS 落在应用 Documents 目录下。返回保存路径。
  Future<String?> captureSnapshotToPath(String relativePath) {
    return SipSdkFlutterPlatform.instance.captureSnapshotToPath(relativePath);
  }

  /// 开始录制通话视频，录制完成后归档到 `relativePath` 指定的位置
  /// （相对媒体根目录的完整路径，含文件名，如
  /// `Doorbell/<deviceId>/video/2026/08/10/101530_123.mp4`）。
  /// 返回录制的临时路径或 null。
  Future<String?> startVideoRecording(String relativePath) {
    return SipSdkFlutterPlatform.instance.startVideoRecording(relativePath);
  }

  Future<String?> stopVideoRecording() {
    return SipSdkFlutterPlatform.instance.stopVideoRecording();
  }

  /// 查询媒体根目录下（`Documents/Doorbell/`，iOS 为应用 Documents/Doorbell）
  /// 已保存的拍照 / 录制视频文件。返回条目列表，每个条目为
  /// `{'relativePath': 'Doorbell/<deviceKey>/<type>/<yyyy>/<MM>/<dd>/<file>',
  ///   'uri': '<content:// 或绝对路径>'}`，按时间倒序（新在前）。
  Future<List<Map<String, dynamic>>?> queryMediaFiles() {
    return SipSdkFlutterPlatform.instance.queryMediaFiles();
  }

  /// 一次性迁移旧媒体目录（`Doorbell` / `lastframe` / `callrecord`）到 app 公共
  /// 根目录 `ParsianTasvir/` 下，方便统一清理。幂等：app 根目录已存在则跳过。
  ///
  /// 迁移后相册（Doorbell）重新枚举即在新根下；缓存（lastframe / callrecord）
  /// 因持久化的绝对路径 / content:// URI 指向旧位置而失效，由下次通话自愈。
  Future<void> migrateMediaToAppRoot() {
    return SipSdkFlutterPlatform.instance.migrateMediaToAppRoot();
  }

  /// 读取某个媒体条目的缩略图（图片 / 视频均可），返回 JPEG 字节；失败返回 null。
  Future<Uint8List?> loadMediaThumbnail(String uri, {int maxSize = 256}) {
    return SipSdkFlutterPlatform.instance.loadMediaThumbnail(uri, maxSize);
  }

  /// 读取某个媒体条目的完整字节（用于图片预览）。
  Future<Uint8List?> loadMediaBytes(String uri) {
    return SipSdkFlutterPlatform.instance.loadMediaBytes(uri);
  }

  /// 全屏播放某个视频媒体条目（原生播放器）。
  Future<void> playMediaVideo(String uri) {
    return SipSdkFlutterPlatform.instance.playMediaVideo(uri);
  }

  /// 把某个媒体条目保存到系统相册（图库）。成功返回 true。
  /// [isVideo] 指示来源是视频还是图片（content:// 路径不带后缀，原生无法自行判断）。
  Future<bool> saveMediaToAlbum(String uri, {bool isVideo = false}) {
    return SipSdkFlutterPlatform.instance.saveMediaToAlbum(uri, isVideo: isVideo);
  }

  /// 按 uri 批量删除媒体条目（content:// 或绝对路径），成功返回 true。
  Future<bool> deleteMediaFiles(List<String> uris) {
    return SipSdkFlutterPlatform.instance.deleteMediaFiles(uris);
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

  /// 切换远端视频显示比例：originalRatio=true → 1:1 按实际比例(留黑边)，
  /// originalRatio=false → 铺满(拉伸铺满，变形)。默认 1:1。
  Future<void> setImageRatio(bool originalRatio) {
    return SipSdkFlutterPlatform.instance.setImageRatio(originalRatio);
  }

  /// 清空远端视频表面的残留画面（只留深灰底色），用于挂断/切换通道。
  Future<void> clearVideo() {
    return SipSdkFlutterPlatform.instance.clearVideo();
  }
}
