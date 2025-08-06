class SIPSDKVideoDecodeConfig {
  final bool enable;
  final int maxWidth;
  final int maxHeight;
  final bool combinSpsPpsIdr;

  SIPSDKVideoDecodeConfig({
    required this.enable,
    required this.maxWidth,
    required this.maxHeight,
    required this.combinSpsPpsIdr,
  });

  // 将对象转换为 JSON 格式
  Map<String, Object?> toJson() => {
        'enable': enable,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'combinSpsPpsIdr': combinSpsPpsIdr,
      };

  // 从 JSON 构造对象
  factory SIPSDKVideoDecodeConfig.fromJson(Map<String, dynamic> json) {
    return SIPSDKVideoDecodeConfig(
      enable: json['enable'] as bool,
      maxWidth: json['maxWidth'] as int,
      maxHeight: json['maxHeight'] as int,
      combinSpsPpsIdr: json['combinSpsPpsIdr'] as bool,
    );
  }
}
