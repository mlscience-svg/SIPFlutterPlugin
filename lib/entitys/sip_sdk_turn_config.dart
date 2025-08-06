class SIPSDKTURNConfig {
  final bool enable;
  final String? server;
  final String? realm;
  final String? username;
  final String? password;

  SIPSDKTURNConfig({
    this.enable = false,
    this.server,
    this.realm,
    this.username,
    this.password,
  });

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'server': server,
    'realm': realm,
    'username': username,
    'password': password,
  };
}
