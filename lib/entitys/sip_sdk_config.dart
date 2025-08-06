import 'sip_sdk_stun_config.dart';
import 'sip_sdk_media_config.dart';

class SIPSDKConfig {
  final String baseUrl;
  final String clientId;
  final String clientSecret;
  final int port;
  final String? publicAddr;
  final int logLevel;
  final String userAgent;
  final int workerThreadCount;
  final bool enableVideo;
  final bool videoOutAutoTransmit;
  final bool allowMultipleConnections;
  final bool domainNameDirectRegistrar;
  final bool doesItSupportBroadcast;
  final STUNConfig? stunConfig;
  final SIPSDKMediaConfig? mediaConfig;

  SIPSDKConfig({
    this.baseUrl = "",
    this.clientId = "",
    this.clientSecret = "",
    this.port = 58581,
    this.publicAddr,
    this.logLevel = 4,
    this.userAgent = "",
    this.workerThreadCount = 1,
    this.enableVideo = true,
    this.videoOutAutoTransmit = true,
    this.allowMultipleConnections = false,
    this.domainNameDirectRegistrar = false,
    this.doesItSupportBroadcast = false,
    this.stunConfig,
    this.mediaConfig,
  });

  Map<String, Object?> toJson() {
    return {
      'baseUrl': baseUrl,
      'clientId': clientId,
      'clientSecret': clientSecret,
      'port': port,
      'publicAddr': publicAddr,
      'logLevel': logLevel,
      'userAgent': userAgent,
      'workerThreadCount': workerThreadCount,
      'enableVideo': enableVideo,
      'videoOutAutoTransmit': videoOutAutoTransmit,
      'allowMultipleConnections': allowMultipleConnections,
      'domainNameDirectRegistrar': domainNameDirectRegistrar,
      'doesItSupportBroadcast': doesItSupportBroadcast,
      'stunConfig': stunConfig?.toJson(),
      'mediaConfig': mediaConfig?.toJson(),
    };
  }

  factory SIPSDKConfig.fromJson(Map<String, dynamic> json) {
    return SIPSDKConfig(
      baseUrl: json['baseUrl'] as String? ?? "",
      clientId: json['clientId'] as String? ?? "",
      clientSecret: json['clientSecret'] as String? ?? "",
      port: json['port'] is int ? json['port'] as int : 58581,
      publicAddr: json['publicAddr'] as String?,
      logLevel: json['logLevel'] is int ? json['logLevel'] as int : 4,
      userAgent: json['userAgent'] as String? ?? "",
      workerThreadCount: json['workerThreadCount'] is int
          ? json['workerThreadCount'] as int
          : 1,
      enableVideo: json['enableVideo'] is bool
          ? json['enableVideo'] as bool
          : true,
      videoOutAutoTransmit: json['videoOutAutoTransmit'] is bool
          ? json['videoOutAutoTransmit'] as bool
          : true,
      allowMultipleConnections: json['allowMultipleConnections'] is bool
          ? json['allowMultipleConnections'] as bool
          : false,
      domainNameDirectRegistrar: json['domainNameDirectRegistrar'] is bool
          ? json['domainNameDirectRegistrar'] as bool
          : false,
      doesItSupportBroadcast: json['doesItSupportBroadcast'] is bool
          ? json['doesItSupportBroadcast'] as bool
          : false,
      stunConfig:
          json['stunConfig'] != null &&
              json['stunConfig'] is Map<String, dynamic>
          ? STUNConfig.fromJson(json['stunConfig'] as Map<String, dynamic>)
          : null,
      mediaConfig:
          json['mediaConfig'] != null &&
              json['mediaConfig'] is Map<String, dynamic>
          ? SIPSDKMediaConfig.fromJson(
              json['mediaConfig'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
