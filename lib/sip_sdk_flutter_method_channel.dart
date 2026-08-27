import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_local_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_message.dart';
import 'package:sip_sdk_flutter/sip_sdk_callbacks.dart';

import 'entitys/sip_sdk_call_param.dart';
import 'entitys/sip_sdk_call_status_param.dart';
import 'entitys/sip_sdk_camera_config.dart';
import 'entitys/sip_sdk_config.dart';
import 'entitys/sip_sdk_dtmf_info.dart';
import 'entitys/sip_sdk_find_incoming_param.dart';
import 'entitys/sip_sdk_ft_complete_param.dart';
import 'entitys/sip_sdk_ft_config.dart';
import 'entitys/sip_sdk_ft_offer_param.dart';
import 'entitys/sip_sdk_ft_param.dart';
import 'entitys/sip_sdk_ft_progress.dart';
import 'entitys/sip_sdk_ft_request_info.dart';
import 'entitys/sip_sdk_ft_request_param.dart';
import 'entitys/sip_sdk_ft_result.dart';
import 'entitys/sip_sdk_registrar_config.dart';
import 'sip_sdk_flutter_platform_interface.dart';

/// An implementation of [SipSdkFlutterPlatform] that uses method channels.
class MethodChannelSipSdkFlutter extends SipSdkFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sip_sdk_flutter');
  late SIPSDKCallbacks callbacks;

  @override
  Future<Void?> setupCallbacks(SIPSDKCallbacks callbacks) async {
    this.callbacks = callbacks;
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onInitCompleted':
          var args = call.arguments as Map;
          callbacks.onInitCompleted(args['state'], args['message']);
          break;
        case 'onStopCompleted':
          callbacks.onStopCompleted();
          break;
        case 'onRegistrarState':
          var args = call.arguments as Map;
          callbacks.onRegistrarState(args['state']);
          break;
        case 'onIncomingCall':
          final callParam = SIPSDKCallParam.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onIncomingCall(callParam);
          break;
        case 'onFindIncoming':
          final param = SIPSDKFindIncomingParam.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onFindIncoming(param);
          break;
        case 'onDtmfInfo':
          final dtmfInfo = SIPSDKDtmfInfo.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onDtmfInfo(dtmfInfo);
          break;
        case 'onMessage':
          final message = SIPSDKMessage.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onMessage(message);
          break;
        case 'onMessageState':
          var args = call.arguments as Map;
          final message = SIPSDKMessage.fromMap(
            Map<String, dynamic>.from(args['message']),
          );
          callbacks.onMessageState(args['state'], message);
          break;
        case 'onCallState':
          var args = Map<String, dynamic>.from(call.arguments);
          callbacks.onCallState(SIPSDKCallStatusParam.fromJson(args));
          break;
        case 'onExpireWarning':
          var args = call.arguments as Map;
          final expireTimeStr = args['expireTime'] as String?;
          final currentTimeStr = args['currentTime'] as String?;
          if (expireTimeStr != null && currentTimeStr != null) {
            final expireTime = DateTime.tryParse(expireTimeStr);
            final currentTime = DateTime.tryParse(currentTimeStr);
            if (expireTime != null && currentTime != null) {
              callbacks.onExpireWarning(expireTime, currentTime);
            }
          }
          break;
        case 'onCameraStateChange':
          var args = call.arguments as Map;
          final state =
              args['state'] is bool ? args['state'] : args['state'] == 1;
          callbacks.onCameraStateChange(state);
          break;
        case 'onActivityCheck':
          callbacks.onActivityCheck();
          break;
        case 'onFTOffer':
          final param = SIPSDKFTOfferParam.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onFTOffer(param);
          break;
        case 'onFTRequest':
          final info = SIPSDKFTRequestInfo.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onFTRequest(info);
          break;
        case 'onFTRequestResult':
          final args = call.arguments as Map;
          callbacks.onFTRequestResult(
            args['reqId'] ?? 0,
            args['ok'] ?? false,
            args['reason'] ?? '',
          );
          break;
        case 'onFTProgress':
          final progress = SIPSDKFTProgress.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onFTProgress(progress);
          break;
        case 'onFTComplete':
          final param = SIPSDKFTCompleteParam.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          callbacks.onFTComplete(param);
          break;
        default:
          debugPrint("未知方法: ${call.method}");
      }
    });
    return null;
  }

  @override
  Future<Void?> initSDK(SIPSDKConfig config) async {
    return await methodChannel.invokeMethod<Void>('initSDK', config.toJson());
  }

  @override
  Future<Void?> initToken(SIPSDKConfig config) async {
    return await methodChannel.invokeMethod<Void>('initToken', config.toJson());
  }

  @override
  Future<Void?> localAccount(SIPSDKLocalConfig config) async {
    return await methodChannel.invokeMethod<Void>(
        'localAccount', config.toJson());
  }

  @override
  Future<Void?> remoteAccount(SIPSDKRegistrarConfig config) async {
    return await methodChannel.invokeMethod<Void>(
        'remoteAccount', config.toJson());
  }

  @override
  Future<void> delRemoteAccount() async {
    return await methodChannel.invokeMethod<void>('delRemoteAccount');
  }

  @override
  Future<void> cameraOpen(SIPSDKCameraConfig config) async {
    return await methodChannel.invokeMethod<void>(
        'cameraOpen', config.toJson());
  }

  @override
  Future<Void?> cameraClose() async {
    return await methodChannel.invokeMethod<Void>('cameraClose');
  }

  @override
  Future<Uint8List?> captureSnapshot() async {
    return await methodChannel.invokeMethod<Uint8List>('captureSnapshot');
  }

  @override
  Future<String?> captureSnapshotToPath(String relativePath) async {
    return await methodChannel.invokeMethod<String>(
      'saveSnapshotToDocuments',
      {'relativePath': relativePath},
    );
  }

  @override
  Future<String?> startVideoRecording(String relativePath) async {
    return await methodChannel.invokeMethod<String>('startVideoRecording', {
      'relativePath': relativePath,
    });
  }

  @override
  Future<String?> stopVideoRecording() async {
    return await methodChannel.invokeMethod<String>('stopVideoRecording');
  }

  @override
  Future<List<Map<String, dynamic>>?> queryMediaFiles() async {
    final raw = await methodChannel.invokeMethod<List<dynamic>>(
      'queryMediaFiles',
    );
    if (raw == null) return null;
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Future<void> migrateMediaToAppRoot() async {
    await methodChannel.invokeMethod<void>('migrateMediaToAppRoot');
  }

  @override
  Future<Uint8List?> loadMediaThumbnail(String uri, int maxSize) async {
    return await methodChannel.invokeMethod<Uint8List>('loadMediaThumbnail', {
      'uri': uri,
      'maxSize': maxSize,
    });
  }

  @override
  Future<Uint8List?> loadMediaBytes(String uri) async {
    return await methodChannel.invokeMethod<Uint8List>('loadMediaBytes', {
      'uri': uri,
    });
  }

  @override
  Future<void> playMediaVideo(String uri) async {
    return await methodChannel.invokeMethod<void>('playMediaVideo', {
      'uri': uri,
    });
  }

  @override
  Future<bool> saveMediaToAlbum(String uri, {bool isVideo = false}) async {
    return (await methodChannel.invokeMethod<bool>('saveMediaToAlbum', {
      'uri': uri,
      'isVideo': isVideo,
    })) ??
        false;
  }

  @override
  Future<String?> extractVideoFrame(
    String uri,
    int positionMs,
    String relativePath,
  ) async {
    return await methodChannel.invokeMethod<String>('extractVideoFrame', {
      'uri': uri,
      'positionMs': positionMs,
      'relativePath': relativePath,
    });
  }

  @override
  Future<String?> clipVideo(
    String uri,
    int startUs,
    int endUs,
    String relativePath,
  ) async {
    return await methodChannel.invokeMethod<String>('clipVideo', {
      'uri': uri,
      'startUs': startUs,
      'endUs': endUs,
      'relativePath': relativePath,
    });
  }

  @override
  Future<bool> deleteMediaFiles(List<String> uris) async {
    return (await methodChannel.invokeMethod<bool>('deleteMediaFiles', {
      'uris': uris,
    })) ??
        false;
  }

  @override
  Future<String?> call(
    int type, {
    String? username,
    String? remoteIp,
    bool? transmitVideo,
    bool? transmitSound,
    Map<String, String>? headers,
  }) async {
    return await methodChannel.invokeMethod<String>('call', {
      'type': type,
      'username': username,
      'remoteIp': remoteIp,
      'transmitVideo': transmitVideo,
      'transmitSound': transmitSound,
      'headers': headers,
    });
  }

  @override
  Future<void> answer(int code, [String? callUuid]) async {
    return await methodChannel.invokeMethod<void>('answer', {
      'code': code,
      'callUuid': callUuid,
    });
  }

  @override
  Future<void> sendDtmfInfo(int type, String content, String callUuid) async {
    return await methodChannel.invokeMethod<void>('sendDtmfInfo', {
      'dtmfInfoType': type,
      'content': content,
      'callUuid': callUuid,
    });
  }

  @override
  Future<void> sendMessage(
    int type,
    String content, {
    String? username,
    String? remoteIp,
  }) async {
    return await methodChannel.invokeMethod<void>('sendMessage', {
      'type': type,
      'username': username,
      'remoteIp': remoteIp,
      'content': content,
    });
  }

  @override
  Future<void> hangup(int code, [String? callUuid]) async {
    return await methodChannel.invokeMethod<void>('hangup', {
      'code': code,
      'callUuid': callUuid,
    });
  }

  @override
  Future<void> dump() async {
    return await methodChannel.invokeMethod<void>('dump');
  }

  @override
  Future<void> handleIpChange() async {
    return await methodChannel.invokeMethod<void>('handleIpChange');
  }

  @override
  Future<void> destroy() async {
    return await methodChannel.invokeMethod<void>('destroy');
  }

  @override
  Future<Void?> startRecording([int? sampleRate]) async {
    return await methodChannel.invokeMethod<Void>('startRecording', {
      'sampleRate': sampleRate,
    });
  }

  @override
  Future<Void?> stopRecording() async {
    return await methodChannel.invokeMethod<Void>('stopRecording');
  }

  @override
  Future<Void?> startPlaying([int? sampleRate]) async {
    return await methodChannel.invokeMethod<Void>('startPlaying', {
      'sampleRate': sampleRate,
    });
  }

  @override
  Future<Void?> stopPlaying() async {
    return await methodChannel.invokeMethod<Void>('stopPlaying');
  }

  @override
  Future<bool?> isMute() async {
    return await methodChannel.invokeMethod<bool>('isMute');
  }

  @override
  Future<void> setMute(bool mute) async {
    return await methodChannel.invokeMethod<void>('setMute', {
      'mute': mute,
    });
  }

  @override
  Future<bool?> isSpeaker() async {
    return await methodChannel.invokeMethod<bool>('isSpeaker');
  }

  @override
  Future<void> setSpeaker(bool speaker) async {
    return await methodChannel.invokeMethod<void>('setSpeaker', {
      'speaker': speaker,
    });
  }

  @override
  Future<void> setImageRatio(bool originalRatio) async {
    return await methodChannel.invokeMethod<void>('setImageRatio', {
      'originalRatio': originalRatio,
    });
  }

  @override
  Future<void> clearVideo() async {
    return await methodChannel.invokeMethod<void>('clearVideo');
  }

  @override
  Future<int> setFTConfig(SIPSDKFTConfig config) async {
    return await methodChannel.invokeMethod<int>('setFTConfig', config.toJson()) ?? 0;
  }

  @override
  Future<SIPSDKFTResult> sendFile(SIPSDKFTParam param) async {
    final raw = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'sendFile',
      param.toJson(),
    );
    return SIPSDKFTResult.fromMap(Map<String, dynamic>.from(raw ?? const {}));
  }

  @override
  Future<SIPSDKFTResult> requestFile(SIPSDKFTRequestParam param) async {
    final raw = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'requestFile',
      param.toJson(),
    );
    return SIPSDKFTResult.fromMap(Map<String, dynamic>.from(raw ?? const {}));
  }

  @override
  Future<int> respondRequest(int reqId, bool accept, String filePath) async {
    return await methodChannel.invokeMethod<int>('respondRequest', {
      'reqId': reqId,
      'accept': accept,
      'filePath': filePath,
    }) ?? 0;
  }

  @override
  Future<int> acceptFile(int ftId, String savePath) async {
    return await methodChannel.invokeMethod<int>('acceptFile', {
      'ftId': ftId,
      'savePath': savePath,
    }) ?? 0;
  }

  @override
  Future<String?> moveToDocuments(String sourcePath, String relativePath) async {
    return await methodChannel.invokeMethod<String>('moveToDocuments', {
      'sourcePath': sourcePath,
      'relativePath': relativePath,
    });
  }

  @override
  Future<String?> findCallRecordMedia(
    String deviceKey,
    String fileName, {
    String directory = 'callrecord',
  }) async {
    return await methodChannel.invokeMethod<String>('findCallRecordMedia', {
      'deviceKey': deviceKey,
      'fileName': fileName,
      'directory': directory,
    });
  }

  @override
  Future<String?> resolveMediaPath(String uri) async {
    return await methodChannel.invokeMethod<String>('resolveMediaPath', {
      'uri': uri,
    });
  }

  @override
  Future<int?> createVideoPlayer(String uri) async {
    return await methodChannel.invokeMethod<int>('createVideoPlayer', {
      'uri': uri,
    });
  }

  @override
  Future<void> videoPlayerPlay(int textureId) async {
    await methodChannel.invokeMethod<void>('videoPlayerPlay', {
      'textureId': textureId,
    });
  }

  @override
  Future<void> videoPlayerPause(int textureId) async {
    await methodChannel.invokeMethod<void>('videoPlayerPause', {
      'textureId': textureId,
    });
  }

  @override
  Future<void> videoPlayerSeekTo(int textureId, int ms) async {
    await methodChannel.invokeMethod<void>('videoPlayerSeekTo', {
      'textureId': textureId,
      'ms': ms,
    });
  }

  @override
  Future<Map<String, dynamic>?> videoPlayerState(int textureId) async {
    final raw = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'videoPlayerState',
      {'textureId': textureId},
    );
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  Future<void> disposeVideoPlayer(int textureId) async {
    await methodChannel.invokeMethod<void>('disposeVideoPlayer', {
      'textureId': textureId,
    });
  }

  @override
  Future<int> rejectFile(int ftId, String reason) async {
    return await methodChannel.invokeMethod<int>('rejectFile', {
      'ftId': ftId,
      'reason': reason,
    }) ?? 0;
  }

  @override
  Future<int> cancelFile(int ftId) async {
    return await methodChannel.invokeMethod<int>('cancelFile', {
      'ftId': ftId,
    }) ?? 0;
  }

  @override
  Future<int> getFileState(int ftId) async {
    return await methodChannel.invokeMethod<int>('getFileState', {
      'ftId': ftId,
    }) ?? 0;
  }
}
