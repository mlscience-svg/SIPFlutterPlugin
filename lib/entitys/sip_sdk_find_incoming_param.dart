class SIPSDKFindIncomingParam {
  final int currentType;
  final int transportType;
  final String transportName;
  final String toDomain;
  final String toUsername;
  final String fromDomain;
  final String fromUsername;
  final String requestDomain;
  final String requestUsername;

  SIPSDKFindIncomingParam({
    required this.currentType,
    required this.transportType,
    required this.transportName,
    required this.toDomain,
    required this.toUsername,
    required this.fromDomain,
    required this.fromUsername,
    required this.requestDomain,
    required this.requestUsername,
  });

  factory SIPSDKFindIncomingParam.fromMap(Map<String, dynamic> map) {
    return SIPSDKFindIncomingParam(
      currentType: map['currentType'] ?? -1,
      transportType: map['transportType'] ?? 0,
      transportName: map['transportName'] ?? '',
      toDomain: map['toDomain'] ?? '',
      toUsername: map['toUsername'] ?? '',
      fromDomain: map['fromDomain'] ?? '',
      fromUsername: map['fromUsername'] ?? '',
      requestDomain: map['requestDomain'] ?? '',
      requestUsername: map['requestUsername'] ?? '',
    );
  }

  @override
  String toString() {
    return 'SIPSDKFindIncomingParam{currentType: $currentType, transportType: $transportType, transportName: $transportName, toDomain: $toDomain, toUsername: $toUsername, fromDomain: $fromDomain, fromUsername: $fromUsername, requestDomain: $requestDomain, requestUsername: $requestUsername}';
  }
}
