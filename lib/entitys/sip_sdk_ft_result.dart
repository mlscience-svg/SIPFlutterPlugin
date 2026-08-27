/// 发送文件 / 请求文件的结果（sendFile 回填 [ftId]，requestFile 回填 [reqId]）。
class SIPSDKFTResult {
  /// 调用状态码（0 表示成功，失败为负错误码）
  final int code;

  /// 传输会话 id（sendFile 成功回填）
  final int ftId;

  /// 请求 id（requestFile 成功回填，用于和 onFTRequestResult 对应）
  final int reqId;

  SIPSDKFTResult({
    this.code = 0,
    this.ftId = 0,
    this.reqId = 0,
  });

  /// 是否提交成功。
  bool get success => code == 0;

  factory SIPSDKFTResult.fromMap(Map<String, dynamic> map) {
    return SIPSDKFTResult(
      code: map['code'] ?? 0,
      ftId: map['ftId'] ?? 0,
      reqId: map['reqId'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SIPSDKFTResult{code: $code, ftId: $ftId, reqId: $reqId}';
  }
}
