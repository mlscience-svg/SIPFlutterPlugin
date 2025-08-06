class SIPSDKMediaH264Fmtp {
  final String profileLevelId;
  final String packetizationMode;

  SIPSDKMediaH264Fmtp({
    required this.profileLevelId,
    required this.packetizationMode,
  });

  // 将对象转换为 JSON 格式
  Map<String, Object?> toJson() => {
        'profileLevelId': profileLevelId,
        'packetizationMode': packetizationMode,
      };

  // 从 JSON 构造对象
  factory SIPSDKMediaH264Fmtp.fromJson(Map<String, dynamic> json) {
    return SIPSDKMediaH264Fmtp(
      profileLevelId: json['profileLevelId'] as String,
      packetizationMode: json['packetizationMode'] as String,
    );
  }
}
