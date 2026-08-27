import 'entitys/sip_sdk_call_param.dart';
import 'entitys/sip_sdk_call_status_param.dart';
import 'entitys/sip_sdk_dtmf_info.dart';
import 'entitys/sip_sdk_find_incoming_param.dart';
import 'entitys/sip_sdk_ft_complete_param.dart';
import 'entitys/sip_sdk_ft_offer_param.dart';
import 'entitys/sip_sdk_ft_progress.dart';
import 'entitys/sip_sdk_ft_request_info.dart';
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

  // ---- 文件传输（FT） ----

  /// 收到对端文件传输请求（push：对端发文件给我），需 [SipSdkFlutter.acceptFile] / [SipSdkFlutter.rejectFile] 决定是否接收。
  void onFTOffer(SIPSDKFTOfferParam param);

  /// 收到对端请求文件（pull：对端要我从本地发文件给它），需 [SipSdkFlutter.respondRequest] 同意/拒绝。
  void onFTRequest(SIPSDKFTRequestInfo info);

  /// 我发起的文件请求结果（reqId 对应 [SipSdkFlutter.requestFile] 回填的 id；ok=true 对端同意，接下来会收到 offer）。
  void onFTRequestResult(int reqId, bool ok, String reason);

  /// 传输进度回调。
  void onFTProgress(SIPSDKFTProgress progress);

  /// 传输结束回调（完成/失败/取消都会触发，通过 error 区分）。
  void onFTComplete(SIPSDKFTCompleteParam param);
}
