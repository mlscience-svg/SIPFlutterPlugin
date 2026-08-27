import 'sip_sdk_ft_file_meta.dart';

/// 收到对端请求文件（pull：对端要我从本地发文件给它）时的参数。
class SIPSDKFTRequestInfo {
  /// 请求 id（回应对应用它）
  final int reqId;

  /// 请求到达的账号 uuid
  final int accUuid;

  /// 请求方账号
  final String username;

  /// 请求方 IP
  final String remoteIp;

  /// 对方请求的文件元信息（name=请求的文件名，size 通常为 0）
  final SIPSDKFTFileMeta file;

  SIPSDKFTRequestInfo({
    this.reqId = 0,
    this.accUuid = 0,
    this.username = '',
    this.remoteIp = '',
    SIPSDKFTFileMeta? file,
  }) : file = file ?? SIPSDKFTFileMeta();

  factory SIPSDKFTRequestInfo.fromMap(Map<String, dynamic> map) {
    return SIPSDKFTRequestInfo(
      reqId: map['reqId'] ?? 0,
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
    return 'SIPSDKFTRequestInfo{reqId: $reqId, accUuid: $accUuid, '
        'username: $username, remoteIp: $remoteIp, file: $file}';
  }
}
