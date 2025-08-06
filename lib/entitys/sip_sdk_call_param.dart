class SIPSDKCallParam {
  final int callType;
  final String username;
  final String remoteIp;
  final Map<String, String> headers;
  final String callUUID;
  final bool transmitVideo;
  final bool transmitSound;

  SIPSDKCallParam({
    required this.callType,
    required this.username,
    required this.remoteIp,
    required this.headers,
    required this.callUUID,
    required this.transmitVideo,
    required this.transmitSound,
  });

  factory SIPSDKCallParam.fromMap(Map<String, dynamic> map) {
    final headerMap = Map<String, String>.from(map['headers'] ?? {});

    return SIPSDKCallParam(
      callType: map['callType'] ?? 0,
      username: map['username'] ?? '',
      remoteIp: map['remoteIp'] ?? '',
      headers: headerMap,
      callUUID: map['callUUID'] ?? '',
      transmitVideo: (map['transmitVideo'] ?? 0) == 1,
      transmitSound: (map['transmitSound'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callType': callType,
      'username': username,
      'remoteIp': remoteIp,
      'headers': headers,
      'callUUID': callUUID,
      'transmitVideo': transmitVideo ? 1 : 0,
      'transmitSound': transmitSound ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'SIPSDKCallParam{callType: $callType, username: $username, remoteIp: $remoteIp, headers: $headers, callUUID: $callUUID, transmitVideo: $transmitVideo, transmitSound: $transmitSound}';
  }
}
