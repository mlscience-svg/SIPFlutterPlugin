class SIPSDKLocalConfig {
  final String? username;
  final String? proxy;
  final int proxyPort;
  final bool enableStreamControl;
  final int streamElapsed;
  final int startKeyframeCount;
  final int startKeyframeInterval;

  SIPSDKLocalConfig({
    this.username,
    this.proxy,
    this.proxyPort = 0,
    this.enableStreamControl = false,
    this.streamElapsed = 0,
    this.startKeyframeCount = 120,
    this.startKeyframeInterval = 1000,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'proxy': proxy,
    'proxyPort': proxyPort,
    'enableStreamControl': enableStreamControl,
    'streamElapsed': streamElapsed,
    'startKeyframeCount': startKeyframeCount,
    'startKeyframeInterval': startKeyframeInterval,
  };
}
