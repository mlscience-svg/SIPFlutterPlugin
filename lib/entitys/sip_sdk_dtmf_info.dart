class SIPSDKDtmfInfo {
  final String callUUID;
  final int dtmfInfoType;
  final String contentType;
  final String content;

  SIPSDKDtmfInfo({
    required this.callUUID,
    required this.dtmfInfoType,
    required this.contentType,
    required this.content,
  });

  factory SIPSDKDtmfInfo.fromMap(Map<String, dynamic> map) {
    return SIPSDKDtmfInfo(
      callUUID: map['callUUID'] ?? '',
      dtmfInfoType: map['dtmfInfoType'] ?? 0,
      contentType: map['contentType'] ?? '',
      content: map['content'] ?? '',
    );
  }

  @override
  String toString() {
    return 'SIPSDKDtmfInfo{callUUID: $callUUID, dtmfInfoType: $dtmfInfoType, contentType: $contentType, content: $content}';
  }
}
