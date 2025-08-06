import 'package:sip_sdk_flutter/entitys/sip_sdk_local_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_turn_config.dart';

class SIPSDKRegistrarConfig {
  final String? domain;
  final String? username;
  final String? password;
  final String? transport;
  final String? serverAddr;
  final int serverPort;
  final Map<String, String>? headers;
  final String? proxy;
  final int proxyPort;
  final bool enableStreamControl;
  final int streamElapsed;
  final int startKeyframeCount;
  final int startKeyframeInterval;
  final SIPSDKTURNConfig? turnConfig;
  final SIPSDKLocalConfig? localConfig;

  SIPSDKRegistrarConfig({
    this.domain,
    this.username,
    this.password,
    this.transport,
    this.serverAddr,
    this.serverPort = 0,
    this.headers,
    this.proxy,
    this.proxyPort = 0,
    this.enableStreamControl = false,
    this.streamElapsed = 2,
    this.startKeyframeCount = 120,
    this.startKeyframeInterval = 1000,
    this.turnConfig,
    this.localConfig,
  });

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'username': username,
    'password': password,
    'transport': transport,
    'serverAddr': serverAddr,
    'serverPort': serverPort,
    'headers': headers,
    'proxy': proxy,
    'proxyPort': proxyPort,
    'enableStreamControl': enableStreamControl,
    'streamElapsed': streamElapsed,
    'startKeyframeCount': startKeyframeCount,
    'startKeyframeInterval': startKeyframeInterval,
    'turnConfig': turnConfig?.toJson(),
    'localConfig': localConfig?.toJson(),
  };
}
