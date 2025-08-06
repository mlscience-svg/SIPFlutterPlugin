import 'package:sip_sdk_flutter/entitys/sip_sdk_encode_rc_modes.dart';

class SIPSDKVideoEncodeConfig {
  final bool enable;
  final int width;
  final int height;
  final int? fps;
  final int? bps;
  final int? minBps;
  final int? maxBps;
  final SIPSDKENCODE_RC_MODES? rcMode;
  final bool? frameSkip;
  final int? qp;

  SIPSDKVideoEncodeConfig({
    required this.enable,
    required this.width,
    required this.height,
    this.fps,
    this.bps,
    this.minBps,
    this.maxBps,
    this.rcMode,
    this.frameSkip,
    this.qp,
  });

  // 将对象转换为 JSON 格式
  Map<String, Object?> toJson() => {
        'enable': enable,
        'width': width,
        'height': height,
        'fps': fps,
        'bps': bps,
        'minBps': minBps,
        'maxBps': maxBps,
        'rcMode': rcMode?.index,
        'frameSkip': frameSkip,
        'qp': qp,
      };

  // 从 JSON 构造对象
  factory SIPSDKVideoEncodeConfig.fromJson(Map<String, dynamic> json) {
    return SIPSDKVideoEncodeConfig(
      enable: json['enable'] as bool,
      width: json['width'] as int,
      height: json['height'] as int,
      fps: json['fps'] as int?,
      bps: json['bps'] as int?,
      minBps: json['minBps'] as int?,
      maxBps: json['maxBps'] as int?,
      rcMode: json['rcMode'] != null
          ? SIPSDKENCODE_RC_MODES.values[json['rcMode']]
          : null,
      frameSkip: json['frameSkip'] as bool?,
      qp: json['qp'] as int?,
    );
  }
}
