import 'sip_sdk_ft_file_meta.dart';

/// 收到对端文件传输请求（push：对端发文件给我）时的参数。
class SIPSDKFTOfferParam {
  /// 传输会话 id（accept/reject 时回填）
  final int ftId;

  /// offer 到达的账号 uuid
  final int accUuid;

  /// 发送方账号
  final String username;

  /// 发送方 IP
  final String remoteIp;

  /// 文件元信息
  final SIPSDKFTFileMeta file;

  SIPSDKFTOfferParam({
    this.ftId = 0,
    this.accUuid = 0,
    this.username = '',
    this.remoteIp = '',
    SIPSDKFTFileMeta? file,
  }) : file = file ?? SIPSDKFTFileMeta();

  factory SIPSDKFTOfferParam.fromMap(Map<String, dynamic> map) {
    return SIPSDKFTOfferParam(
      ftId: map['ftId'] ?? 0,
      accUuid: map['accUuid'] ?? 0,
      username: map['username'] ?? '',
      remoteIp: map['remoteIp'] ?? '',
      file: SIPSDKFTFileMeta.fromMap(
        Map<String, dynamic>.from(map['file'] as Map? ?? const {}),
      ),
    );
  }

  @override
  String toString() {
    return 'SIPSDKFTOfferParam{ftId: $ftId, accUuid: $accUuid, '
        'username: $username, remoteIp: $remoteIp, file: $file}';
  }
}
