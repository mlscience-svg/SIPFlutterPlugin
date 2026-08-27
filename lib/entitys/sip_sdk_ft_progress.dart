/// 传输进度回调。
class SIPSDKFTProgress {
  /// 会话 id
  final int ftId;

  /// 当前状态（见 [SIPSDKFTConstants.ftState*]）
  final int state;

  /// 总字节数
  final int bytesTotal;

  /// 已完成字节数
  final int bytesDone;

  /// 0-100
  final int percent;

  /// 当前活跃会话数
  final int activeSessions;

  SIPSDKFTProgress({
    this.ftId = 0,
    this.state = 0,
    this.bytesTotal = 0,
    this.bytesDone = 0,
    this.percent = 0,
    this.activeSessions = 0,
  });

  factory SIPSDKFTProgress.fromMap(Map<String, dynamic> map) {
    return SIPSDKFTProgress(
      ftId: map['ftId'] ?? 0,
      state: map['state'] ?? 0,
      bytesTotal: map['bytesTotal'] ?? 0,
      bytesDone: map['bytesDone'] ?? 0,
      percent: map['percent'] ?? 0,
      activeSessions: map['activeSessions'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SIPSDKFTProgress{ftId: $ftId, state: $state, '
        'bytesTotal: $bytesTotal, bytesDone: $bytesDone, percent: $percent, '
        'activeSessions: $activeSessions}';
  }
}
