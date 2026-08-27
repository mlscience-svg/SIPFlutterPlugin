import 'sip_sdk_stun_config.dart';
import 'sip_sdk_turn_config.dart';

/// 文件传输（FT）模块配置。
///
/// 需在 [SipSdkFlutter.initSDK] / [SipSdkFlutter.initToken] 之前通过
/// [SipSdkFlutter.setFTConfig] 设置；enable 为 true 时 SDK init 完成会自动初始化 FT 模块。
/// 字段填 0 / 不填表示"不配置"，native 会使用与 C 侧一致的默认值。
class SIPSDKFTConfig {
  /// 是否启用文件传输（默认 false）
  bool enable;

  /// 最大并发会话数（C 默认 5）
  int maxSessions;

  /// 滑动窗口大小（C 默认 128，上限 256）
  int windowSize;

  /// 分块大小字节（C 默认 2048，上限 2048）
  int chunkSize;

  /// 初始重传超时 RTO 毫秒（C 默认 1000）
  int initialRtoMs;

  /// 最小重传超时 RTO 毫秒（C 默认 500）
  int rtoMinMs;

  /// 最大连续重传次数（C 默认 5）
  int maxRetransmit;

  /// 会话硬超时毫秒（C 默认 120000）
  int sessionTimeoutMs;

  /// 等对端 answer 超时毫秒（C 默认 30000）
  int answerTimeoutMs;

  /// answer 后 ICE 建连超时毫秒（C 默认 3000）
  int connectTimeoutMs;

  /// 传输中无数据交互超时毫秒（C 默认 5000）
  int inactiveTimeoutMs;

  /// 发送节奏：每轮 poll 最多突发的包数（C 默认 24）
  int burstMax;

  /// 发送批次间隔毫秒（C 默认 3）
  int sendIntervalMs;

  /// KCP 发送窗口段数（C 默认 128）；在途量=窗口×1200，越大吞吐越高内存越大
  int kcpSndwnd;

  /// KCP 接收窗口段数（C 默认 256）；须 ≥ 对端 sndwnd 否则对端发送被收窗卡死
  int kcpRcvwnd;

  /// 发送端 KCP 队列段数上限（C 默认 512）；满则暂停读文件（KCP 流控回压）
  int kcpMaxWaitsnd;

  /// true=关闭 KCP 拥塞控制（nocwnd=1）：在途只受 kcpSndwnd 限制，吞吐更高但会野蛮填满链路，
  /// 挤压共享公网其它流，丢包率高时易重传风暴；仅 P2P/干净链路建议开。默认 false=开启拥塞控制
  bool kcpDisableCc;

  /// STUN 服务器（servers 为空表示 FT 不启用 STUN）
  STUNConfig? stun;

  /// TURN 服务器
  SIPSDKTURNConfig? turn;

  /// 是否启用 IPv6（默认 false）
  bool enableIpv6;

  /// 接收端默认保存目录（对端 offer 到达且 app 未指定保存路径时使用）
  String defaultSaveDir;

  SIPSDKFTConfig({
    this.enable = false,
    this.maxSessions = 0,
    this.windowSize = 0,
    this.chunkSize = 0,
    this.initialRtoMs = 0,
    this.rtoMinMs = 0,
    this.maxRetransmit = 0,
    this.sessionTimeoutMs = 0,
    this.answerTimeoutMs = 0,
    this.connectTimeoutMs = 0,
    this.inactiveTimeoutMs = 0,
    this.burstMax = 0,
    this.sendIntervalMs = 0,
    this.kcpSndwnd = 0,
    this.kcpRcvwnd = 0,
    this.kcpMaxWaitsnd = 0,
    this.kcpDisableCc = false,
    this.stun,
    this.turn,
    this.enableIpv6 = false,
    this.defaultSaveDir = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'enable': enable,
      'maxSessions': maxSessions,
      'windowSize': windowSize,
      'chunkSize': chunkSize,
      'initialRtoMs': initialRtoMs,
      'rtoMinMs': rtoMinMs,
      'maxRetransmit': maxRetransmit,
      'sessionTimeoutMs': sessionTimeoutMs,
      'answerTimeoutMs': answerTimeoutMs,
      'connectTimeoutMs': connectTimeoutMs,
      'inactiveTimeoutMs': inactiveTimeoutMs,
      'burstMax': burstMax,
      'sendIntervalMs': sendIntervalMs,
      'kcpSndwnd': kcpSndwnd,
      'kcpRcvwnd': kcpRcvwnd,
      'kcpMaxWaitsnd': kcpMaxWaitsnd,
      'kcpDisableCc': kcpDisableCc,
      'stun': stun?.toJson(),
      'turn': turn?.toJson(),
      'enableIpv6': enableIpv6,
      'defaultSaveDir': defaultSaveDir,
    };
  }

  @override
  String toString() {
    return 'SIPSDKFTConfig{enable: $enable, maxSessions: $maxSessions, '
        'windowSize: $windowSize, chunkSize: $chunkSize, initialRtoMs: $initialRtoMs, '
        'rtoMinMs: $rtoMinMs, maxRetransmit: $maxRetransmit, '
        'sessionTimeoutMs: $sessionTimeoutMs, answerTimeoutMs: $answerTimeoutMs, '
        'connectTimeoutMs: $connectTimeoutMs, inactiveTimeoutMs: $inactiveTimeoutMs, '
        'burstMax: $burstMax, sendIntervalMs: $sendIntervalMs, '
        'kcpSndwnd: $kcpSndwnd, kcpRcvwnd: $kcpRcvwnd, kcpMaxWaitsnd: $kcpMaxWaitsnd, '
        'kcpDisableCc: $kcpDisableCc, stun: $stun, turn: $turn, '
        'enableIpv6: $enableIpv6, defaultSaveDir: $defaultSaveDir}';
  }
}
