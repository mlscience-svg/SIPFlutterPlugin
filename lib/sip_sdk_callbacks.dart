import 'entitys/sip_sdk_call_param.dart';
import 'entitys/sip_sdk_dtmf_info.dart';
import 'entitys/sip_sdk_message.dart';

abstract class SIPSDKCallbacks {
  void onInitCompleted(int state, String message);

  void onStopCompleted();

  void onRegistrarState(int state);

  void onIncomingCall(SIPSDKCallParam callParam);

  void onDtmfInfo(SIPSDKDtmfInfo dtmfInfo);

  void onMessage(SIPSDKMessage message);

  void onMessageState(int state, SIPSDKMessage message);

  void onCallState(String callUUID, int state);

  void onExpireWarning(DateTime expireTime, DateTime currentTime);

  void onCameraStateChange(bool state);
}
