/// 文件传输（FT）模块常量，与 native 侧 `sip_sdk_ft.h` / Android `SIPSDKFTConstants` 一致。
class SIPSDKFTConstants {
  /* ---- 角色 ---- */
  static const int ftRoleSender = 0;
  static const int ftRoleReceiver = 1;

  /* ---- 会话状态 ---- */
  static const int ftStateNull = 0;
  static const int ftStateNegotiating = 1;
  static const int ftStateIceConnecting = 2;
  static const int ftStateTransferring = 3;
  static const int ftStateComplete = 4;
  static const int ftStateError = 5;
  static const int ftStateCancelled = 6;

  /* ---- 错误码 ---- */
  static const int ftErrNone = 0;
  static const int ftErrBusy = -100;
  static const int ftErrOpenFile = -101;
  static const int ftErrIce = -102;
  static const int ftErrTimeout = -103;
  static const int ftErrPeerCancel = -104;
  static const int ftErrLocalCancel = -105;
  static const int ftErrProtocol = -106;
  static const int ftErrRejected = -107;

  SIPSDKFTConstants._();
}
