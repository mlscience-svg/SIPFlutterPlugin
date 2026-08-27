class STUNConfig {
  final bool enable; // 是否开启 STUN
  final List<String> servers; // 最多8个服务器地址，每个地址最大长度为63字符
  final bool enableIPv6;

  STUNConfig({
    this.enable = false,
    required List<String> servers,
    required this.enableIPv6,
  }) : servers = servers.length > 8 ? servers.sublist(0, 8) : servers;

  // 限制每个服务器地址最长为 63 字符
  bool _validateServer(String server) => server.length <= 63;

  Map<String, Object?> toJson() => {
    'enable': enable,
    'servers': servers.where(_validateServer).toList(),
    'enableIPv6': enableIPv6,
  };

  factory STUNConfig.fromJson(Map<String, dynamic> json) {
    final rawServers = json['servers'];
    List<String> serversList = [];

    if (rawServers is List) {
      serversList = rawServers
          .whereType<String>() // 只保留字符串类型
          .toList();
    }

    return STUNConfig(
      enable: json['enable'] is bool ? json['enable'] as bool : false,
      servers: serversList,
      enableIPv6: json['enableIPv6'] is bool ? json['enableIPv6'] as bool : false,
    );
  }
}