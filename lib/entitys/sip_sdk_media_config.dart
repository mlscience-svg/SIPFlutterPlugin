import 'package:sip_sdk_flutter/entitys/sip_sdk_media_h264_fmtp.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_video_decode_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_video_encode_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_encode_rc_modes.dart';

class SIPSDKMediaConfig {
  final bool? audioOnlyCallConfirmed;
  final int? audioClockRate;
  final double? micGain;
  final double? speakerGain;
  final bool? nsEnable;
  final bool? agcEnable;
  final int? agcMaxGain;
  final int? agcIncrement;
  final int? agcDecrement;
  final double? agcLevel;
  final bool? aecEnable;
  final int? aecEchoMode;
  final int? aecCngMode;
  final int? aecEliminationTime;
  final SIPSDKMediaH264Fmtp? h264Fmtp;
  final SIPSDKVideoDecodeConfig? decodeConfig;
  final SIPSDKVideoEncodeConfig? encodeConfig;

  // 在这里提供默认值
  SIPSDKMediaConfig({
    this.audioOnlyCallConfirmed = false,
    this.audioClockRate = 16000,
    this.micGain = 1.0,
    this.speakerGain = 1.0,
    this.nsEnable = true,
    this.agcEnable = true,
    this.agcMaxGain = 10,
    this.agcIncrement = 3,
    this.agcDecrement = 40,
    this.agcLevel = 4000,
    this.aecEnable = true,
    this.aecEchoMode = 3,
    this.aecCngMode = 0,
    this.aecEliminationTime = 50,
    SIPSDKMediaH264Fmtp? h264Fmtp,
    SIPSDKVideoDecodeConfig? decodeConfig,
    SIPSDKVideoEncodeConfig? encodeConfig,
  })  : h264Fmtp = h264Fmtp ??
            SIPSDKMediaH264Fmtp(
              profileLevelId: '42e01e',
              packetizationMode: '1',
            ),
      decodeConfig = decodeConfig ??
            SIPSDKVideoDecodeConfig(
              enable: true,
              maxWidth: 1920,
              maxHeight: 1080,
              combinSpsPpsIdr: true,
            ),
        encodeConfig = encodeConfig ??
            SIPSDKVideoEncodeConfig(
              enable: true,
              width: 640,
              height: 480,
              fps: 15,
              bps: 512000,
              minBps: 256000,
              maxBps: 1024000,
              rcMode: SIPSDKENCODE_RC_MODES.BITRATE_MODE,
              frameSkip: true,
              qp: 25,
            );

  // 将对象转换为 JSON 格式
  Map<String, Object?> toJson() => {
        'audioOnlyCallConfirmed': audioOnlyCallConfirmed,
        'audioClockRate': audioClockRate,
        'micGain': micGain,
        'speakerGain': speakerGain,
        'nsEnable': nsEnable,
        'agcEnable': agcEnable,
        'agcMaxGain': agcMaxGain,
        'agcIncrement': agcIncrement,
        'agcDecrement': agcDecrement,
        'agcLevel': agcLevel,
        'aecEnable': aecEnable,
        'aecEchoMode': aecEchoMode,
        'aecCngMode': aecCngMode,
        'aecEliminationTime': aecEliminationTime,
        'h264Fmtp': h264Fmtp?.toJson(),
        'decodeConfig': decodeConfig?.toJson(),
        'encodeConfig': encodeConfig?.toJson(),
      };

  // 从 JSON 构造对象
  factory SIPSDKMediaConfig.fromJson(Map<String, dynamic> json) {
    return SIPSDKMediaConfig(
      audioOnlyCallConfirmed: json['audioOnlyCallConfirmed'] as bool?,
      audioClockRate: json['audioClockRate'] as int?,
      micGain: json['micGain'] as double?,
      speakerGain: json['speakerGain'] as double?,
      nsEnable: json['nsEnable'] as bool?,
      agcEnable: json['agcEnable'] as bool?,
      agcMaxGain: json['agcMaxGain'] as int?,
      agcIncrement: json['agcIncrement'] as int?,
      agcDecrement: json['agcDecrement'] as int?,
      agcLevel: (json['agcLevel'] as num?)?.toDouble(),
      aecEnable: json['aecEnable'] as bool?,
      aecEchoMode: json['aecEchoMode'] as int?,
      aecCngMode: json['aecCngMode'] as int?,
      aecEliminationTime: json['aecEliminationTime'] as int?,
      h264Fmtp: json['h264Fmtp'] != null
          ? SIPSDKMediaH264Fmtp.fromJson(json['h264Fmtp'])
          : null,
      decodeConfig: json['decodeConfig'] != null
          ? SIPSDKVideoDecodeConfig.fromJson(json['decodeConfig'])
          : null,
      encodeConfig: json['encodeConfig'] != null
          ? SIPSDKVideoEncodeConfig.fromJson(json['encodeConfig'])
          : null,
    );
  }
}
