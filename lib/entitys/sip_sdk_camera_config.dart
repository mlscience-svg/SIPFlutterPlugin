class SIPSDKCameraConfig {
  final int index;
  final int? width;
  final int? height;
  final int? rotate; // 0, 90, 270

  const SIPSDKCameraConfig({
    required this.index,
    this.width,
    this.height,
    this.rotate,
  });

  // 可选：从 Map 构造，用于 JSON 或参数传递
  factory SIPSDKCameraConfig.fromMap(Map<String, dynamic> json) {
    return SIPSDKCameraConfig(
      index: json['index'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
      rotate: json['rotate'] as int?,
    );
  }

  // 可选：转 Json
  Map<String, Object?> toJson() => {
        'index': index,
        'width': width,
        'height': height,
        'rotate': rotate,
      };
}
