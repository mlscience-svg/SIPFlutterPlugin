/// 请求对端发送文件的参数（pull：主动向对端要文件）。
class SIPSDKFTRequestParam {
  /// 发起请求用的账号 uuid（本 SDK 唯一账号传 0 即可）
  int accUuid;

  /// 请求谁发文件（远程账号必填）
  String username;

  /// 对端 IP（本地账号必填）
  String remoteIp;

  /// 请求的文件名/路径
  String fileName;

  /// 附加信息
  String extra;

  SIPSDKFTRequestParam({
    this.accUuid = 0,
    this.username = '',
    this.remoteIp = '',
    this.fileName = '',
    this.extra = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'accUuid': accUuid,
      'username': username,
      'remoteIp': remoteIp,
      'fileName': fileName,
      'extra': extra,
    };
  }

  @override
  String toString() {
    return 'SIPSDKFTRequestParam{accUuid: $accUuid, username: $username, '
        'remoteIp: $remoteIp, fileName: $fileName, extra: $extra}';
  }
}
