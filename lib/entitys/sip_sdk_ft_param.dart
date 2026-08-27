/// 发送文件的参数。
class SIPSDKFTParam {
  /// 发送使用的账号 uuid（本 SDK 唯一账号传 0 即可）
  int accUuid;

  /// 对端账号（远程账号必填）
  String username;

  /// 对端 IP（本地账号必填）
  String remoteIp;

  /// 待发送文件绝对路径
  String filePath;

  /// 附加信息
  String extra;

  SIPSDKFTParam({
    this.accUuid = 0,
    this.username = '',
    this.remoteIp = '',
    this.filePath = '',
    this.extra = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'accUuid': accUuid,
      'username': username,
      'remoteIp': remoteIp,
      'filePath': filePath,
      'extra': extra,
    };
  }

  @override
  String toString() {
    return 'SIPSDKFTParam{accUuid: $accUuid, username: $username, '
        'remoteIp: $remoteIp, filePath: $filePath, extra: $extra}';
  }
}
