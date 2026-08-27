import 'dart:ffi';
import 'dart:typed_data';

import 'package:sip_sdk_flutter/entitys/sip_sdk_local_config.dart';
import 'package:sip_sdk_flutter/sip_sdk_callbacks.dart';

import 'entitys/sip_sdk_camera_config.dart';
import 'entitys/sip_sdk_config.dart';
import 'entitys/sip_sdk_ft_config.dart';
import 'entitys/sip_sdk_ft_param.dart';
import 'entitys/sip_sdk_ft_request_param.dart';
import 'entitys/sip_sdk_ft_result.dart';
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

  /// 按播放位置从视频抓一帧存为 JPG，返回保存后的 content:// URI / 路径。
  Future<String?> extractVideoFrame(
    String uri,
    int positionMs,
    String relativePath,
  ) {
    return SipSdkFlutterPlatform.instance
        .extractVideoFrame(uri, positionMs, relativePath);
  }

  /// 把视频从 startUs 截到 endUs（微秒）输出一段 MP4，返回保存后的 content:// URI / 路径。
  Future<String?> clipVideo(
    String uri,
    int startUs,
    int endUs,
    String relativePath,
  ) {
    return SipSdkFlutterPlatform.instance
        .clipVideo(uri, startUs, endUs, relativePath);
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

  // ---- 文件传输（FT） ----

  /// 配置文件传输（需在 [initSDK] / [initToken] 之前调用；enable 为 true 时 SDK init 完成会自动初始化 FT 模块）。
  /// 返回状态码，0 表示成功。
  Future<int> setFTConfig(SIPSDKFTConfig config) {
    return SipSdkFlutterPlatform.instance.setFTConfig(config);
  }

  /// 发送文件（异步）。成功后通过 [SIPSDKFTResult.ftId] 拿到会话 id，后续进度/结束走
  /// [SIPSDKCallbacks.onFTProgress] / [SIPSDKCallbacks.onFTComplete]。
  Future<SIPSDKFTResult> sendFile(SIPSDKFTParam param) {
    return SipSdkFlutterPlatform.instance.sendFile(param);
  }

  /// 请求对端发送文件（pull，异步）。成功后通过 [SIPSDKFTResult.reqId] 拿到请求 id，
  /// 结果走 [SIPSDKCallbacks.onFTRequestResult]，对端同意后还会收到 [SIPSDKCallbacks.onFTOffer]。
  Future<SIPSDKFTResult> requestFile(SIPSDKFTRequestParam param) {
    return SipSdkFlutterPlatform.instance.requestFile(param);
  }

  /// 回应对端的文件请求（[SIPSDKCallbacks.onFTRequest] 里调用；accept=true 同意并给本地文件路径，false 拒绝）。
  Future<int> respondRequest(int reqId, bool accept, String filePath) {
    return SipSdkFlutterPlatform.instance.respondRequest(reqId, accept, filePath);
  }

  /// 接受对端的文件传输请求（[SIPSDKCallbacks.onFTOffer] 里调用，savePath 为保存路径含文件名）。
  Future<int> acceptFile(int ftId, String savePath) {
    return SipSdkFlutterPlatform.instance.acceptFile(ftId, savePath);
  }

  /// 把已接收的文件搬进公共存储（与拍照/录像一致）。
  ///
  /// [sourcePath] 为接受时写入的临时文件；[relativePath] 为相对媒体根目录的
  /// 完整路径（含文件名），如 `ParsianTasvir/callrecord/<设备id>/xxx.JPG`。
  /// Q+ 走 MediaStore 返回 content:// URI，≤28 写公共 Documents 返回绝对路径；
  /// 成功删除临时文件。失败/参数为空返回 null。
  Future<String?> moveToDocuments(String sourcePath, String relativePath) {
    return SipSdkFlutterPlatform.instance
        .moveToDocuments(sourcePath, relativePath);
  }

  /// 按 (设备key, 文件名) 查公共目录里的 FT 缓存媒体（content:// URI / 绝对路径），
  /// 未命中返回 null。[directory] 缓存子目录：callrecord=呼叫记录文件，
  /// media=设备媒体库文件。
  Future<String?> findCallRecordMedia(
    String deviceKey,
    String fileName, {
    String directory = 'callrecord',
  }) {
    return SipSdkFlutterPlatform.instance
        .findCallRecordMedia(deviceKey, fileName, directory: directory);
  }

  /// 把媒体条目解析成本地可读的绝对路径（供 media_kit 等原生无法读
  /// content:// 的引擎使用）。绝对路径原样返回；content:// 优先查 MediaStore
  /// `_data`，读不到则流式拷贝到 app cache 目录；其它形式返回 null。
  Future<String?> resolveMediaPath(String uri) {
    return SipSdkFlutterPlatform.instance.resolveMediaPath(uri);
  }

  /// 创建页面内嵌视频播放器（原生 TextureRegistry + MediaPlayer，专为门铃 AVI）。
  ///
  /// 返回 textureId，配合 Flutter 的 `Texture(textureId: ...)` 就地显示画面
  /// （video_player 同款架构，引擎纹理管线渲染可靠）；创建失败返回 null。
  /// 配合 [videoPlayerState] 轮询驱动进度条，结束时调用 [disposeVideoPlayer]。
  Future<int?> createVideoPlayer(String uri) {
    return SipSdkFlutterPlatform.instance.createVideoPlayer(uri);
  }

  /// 播放 / 暂停 / 跳转 / 释放（[textureId] 来自 [createVideoPlayer]）。
  Future<void> videoPlayerPlay(int textureId) {
    return SipSdkFlutterPlatform.instance.videoPlayerPlay(textureId);
  }

  Future<void> videoPlayerPause(int textureId) {
    return SipSdkFlutterPlatform.instance.videoPlayerPause(textureId);
  }

  Future<void> videoPlayerSeekTo(int textureId, int ms) {
    return SipSdkFlutterPlatform.instance.videoPlayerSeekTo(textureId, ms);
  }

  /// 查询播放状态：{position, duration, playing, error?}。
  Future<Map<String, dynamic>?> videoPlayerState(int textureId) {
    return SipSdkFlutterPlatform.instance.videoPlayerState(textureId);
  }

  Future<void> disposeVideoPlayer(int textureId) {
    return SipSdkFlutterPlatform.instance.disposeVideoPlayer(textureId);
  }

  /// 拒绝对端的文件传输请求。
  Future<int> rejectFile(int ftId, String reason) {
    return SipSdkFlutterPlatform.instance.rejectFile(ftId, reason);
  }

  /// 取消传输（发送端或接收端均可）。
  Future<int> cancelFile(int ftId) {
    return SipSdkFlutterPlatform.instance.cancelFile(ftId);
  }

  /// 查询会话状态（成功返回 state 枚举，失败返回负错误码）。
  Future<int> getFileState(int ftId) {
    return SipSdkFlutterPlatform.instance.getFileState(ftId);
  }
}
