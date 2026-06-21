import 'entitys/sip_sdk_call_param.dart';
import 'entitys/sip_sdk_call_status_param.dart';
import 'entitys/sip_sdk_dtmf_info.dart';
import 'entitys/sip_sdk_find_incoming_param.dart';
import 'entitys/sip_sdk_message.dart';

abstract class SIPSDKCallbacks {
  void onInitCompleted(int state, String message);

  void onStopCompleted();

  void onRegistrarState(int state);

  void onIncomingCall(SIPSDKCallParam callParam);

  void onFindIncoming(SIPSDKFindIncomingParam param);

  void onDtmfInfo(SIPSDKDtmfInfo dtmfInfo);

  void onMessage(SIPSDKMessage message);

  void onMessageState(int state, SIPSDKMessage message);

  void onCallState(SIPSDKCallStatusParam param);

  void onExpireWarning(DateTime expireTime, DateTime currentTime);

  void onCameraStateChange(bool state);

  void onActivityCheck();
}
