/// 文件元信息。
class SIPSDKFTFileMeta {
  /// 文件名
  final String name;

  /// 文件大小（字节）
  final int size;

  /// 附加信息
  final String extra;

  SIPSDKFTFileMeta({
    this.name = '',
    this.size = 0,
    this.extra = '',
  });

  factory SIPSDKFTFileMeta.fromMap(Map<String, dynamic> map) {
    return SIPSDKFTFileMeta(
      name: map['name'] ?? '',
      size: map['size'] ?? 0,
      extra: map['extra'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
      'extra': extra,
    };
  }

  @override
  String toString() {
    return 'SIPSDKFTFileMeta{name: $name, size: $size, extra: $extra}';
  }
}
