class SIPSDKConstants {
  // 状态
  static const int SDK_SUCCESS = 0;
  static const int SDK_ERROR_COMMON = -1;

  // 布尔值
  static const int SDK_TRUE = 1;
  static const int SDK_FALSE = 0;

  // 呼叫类型
  static const int SDK_CALL_TYPE_IP = 0;
  static const int SDK_CALL_TYPE_SERVER = 1;

  // 消息类型
  static const int SDK_MESSAGE_TYPE_IP = 0;
  static const int SDK_MESSAGE_TYPE_SERVER = 1;

  // DTMF info类型
  static const int SDK_DTMF_INFO_TYPE = 0;
  static const int SDK_DTMF_INFO_TYPE_CUSTOM = 1;

  // 呼叫状态
  static const int CALL_STATE_NULL = 0;
  static const int CALL_STATE_CALLING = 1;
  static const int CALL_STATE_INCOMING = 2;
  static const int CALL_STATE_EARLY = 3;
  static const int CALL_STATE_CONNECTING = 4;
  static const int CALL_STATE_CONFIRMED = 5;
  static const int CALL_STATE_DISCONNECTED = 6;

  // 关键帧通知
  static const int SDK_MEDIA_NOTIFICATION_SEND_KEYFRAME = 10000;
}
