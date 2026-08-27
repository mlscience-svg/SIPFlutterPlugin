/// 传输结束参数（完成/失败/取消都会触发，通过 error 区分）。
class SIPSDKFTCompleteParam {
  /// 会话 id
  final int ftId;

  /// 本端角色（见 [SIPSDKFTConstants.ftRole*]）
  final int role;

  /// 错误码（正常完成为 ftErrNone）
  final int error;

  /// 传输字节数
  final int bytesTransferred;

  /// 耗时（毫秒）
  final int elapsedMs;

  /// 文件名
  final String fileName;

  /// 保存路径（接收端）
  final String savePath;

  SIPSDKFTCompleteParam({
    this.ftId = 0,
    this.role = 0,
    this.error = 0,
    this.bytesTransferred = 0,
    this.elapsedMs = 0,
    this.fileName = '',
    this.savePath = '',
  });

  factory SIPSDKFTCompleteParam.fromMap(Map<String, dynamic> map) {
    return SIPSDKFTCompleteParam(
      ftId: map['ftId'] ?? 0,
      role: map['role'] ?? 0,
      error: map['error'] ?? 0,
      bytesTransferred: map['bytesTransferred'] ?? 0,
      elapsedMs: map['elapsedMs'] ?? 0,
      fileName: map['fileName'] ?? '',
      savePath: map['savePath'] ?? '',
    );
  }

  @override
  String toString() {
    return 'SIPSDKFTCompleteParam{ftId: $ftId, role: $role, error: $error, '
        'bytesTransferred: $bytesTransferred, elapsedMs: $elapsedMs, '
        'fileName: $fileName, savePath: $savePath}';
  }
}
