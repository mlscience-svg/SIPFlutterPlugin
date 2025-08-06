import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_message.dart';
import 'package:sip_sdk_flutter/sip_sdk_callbacks.dart';

import 'entitys/sip_sdk_call_param.dart';
import 'entitys/sip_sdk_camera_config.dart';
import 'entitys/sip_sdk_config.dart';
import 'entitys/sip_sdk_dtmf_info.dart';
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
          var args = call.arguments as Map;
          callbacks.onCallState(args['callUUID'], args['state']);
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
  Future<Void?> registrar(SIPSDKRegistrarConfig config) async {
    return await methodChannel.invokeMethod<Void>('registrar', config.toJson());
  }

  @override
  Future<void> unRegistrar() async {
    return await methodChannel.invokeMethod<void>('unRegistrar');
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
  Future<String?> call(
    String username,
    Map<String, String> headers,
  ) async {
    return await methodChannel.invokeMethod<String>('call', {
      'username': username,
      'headers': headers,
    });
  }

  @override
  Future<String?> callIP(String ip, Map<String, String> headers) async {
    return await methodChannel.invokeMethod<String>('callIP', {
      'ip': ip,
      'headers': headers,
    });
  }

  @override
  Future<void> answer(int code, [String? callUUID]) async {
    return await methodChannel.invokeMethod<void>('answer', {
      'code': code,
      'callUUID': callUUID,
    });
  }

  @override
  Future<void> sendDtmfInfo(int type, String content, String callUUID) async {
    return await methodChannel.invokeMethod<void>('sendDtmfInfo', {
      'type': type,
      'content': content,
      'callUUID': callUUID,
    });
  }

  @override
  Future<void> sendMessage(String username, String content) async {
    return await methodChannel.invokeMethod<void>('sendMessage', {
      'username': username,
      'content': content,
    });
  }

  @override
  Future<void> sendMessageIP(String ip, String content) async {
    return await methodChannel.invokeMethod<void>('sendMessageIP', {
      'ip': ip,
      'content': content,
    });
  }

  @override
  Future<void> hangup(int code, [String? callUUID]) async {
    return await methodChannel.invokeMethod<void>('hangup', {
      'code': code,
      'callUUID': callUUID,
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
}
