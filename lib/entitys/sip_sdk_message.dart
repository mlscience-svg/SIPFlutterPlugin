class SIPSDKMessage {
  final int messageType;
  final String username;
  final String remoteIp;
  final String content;

  SIPSDKMessage({
    required this.messageType,
    required this.username,
    required this.remoteIp,
    required this.content,
  });

  factory SIPSDKMessage.fromMap(Map<String, dynamic> map) {
    return SIPSDKMessage(
      messageType: map['messageType'] ?? 0,
      username: map['username'] ?? '',
      remoteIp: map['remoteIp'] ?? '',
      content: map['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageType': messageType,
      'username': username,
      'remoteIp': remoteIp,
      'content': content,
    };
  }

  @override
  String toString() {
    return 'SIPSDKMessage{messageType: $messageType, username: $username, remoteIp: $remoteIp, content: $content}';
  }
}