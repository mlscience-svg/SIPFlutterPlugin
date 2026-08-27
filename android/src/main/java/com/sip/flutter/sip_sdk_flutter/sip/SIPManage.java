package com.sip.flutter.sip_sdk_flutter.sip;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraHandle;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraStateChangeCallback;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.entity.SIPSDKCallParam;
import com.sip.sdk.entity.SIPSDKCallStatusParam;
import com.sip.sdk.entity.SIPSDKConfig;
import com.sip.sdk.entity.SIPSDKDtmfInfoParam;
import com.sip.sdk.entity.SIPSDKFindIncomingParam;
import com.sip.sdk.entity.SIPSDKFTCompleteParam;
import com.sip.sdk.entity.SIPSDKFTOfferParam;
import com.sip.sdk.entity.SIPSDKFTProgress;
import com.sip.sdk.entity.SIPSDKFTRequestInfo;
import com.sip.sdk.entity.SIPSDKMediaConfig;
import com.sip.sdk.entity.SIPSDKMessageParam;
import com.sip.sdk.i.SIPSDKFTListener;
import com.sip.sdk.i.SIPSDKListener;

import java.util.HashMap;
import java.util.Map;

public class SIPManage implements SIPSDKListener.InitCompletedListener,
        SIPSDKListener.RegistryStateListener,
        SIPSDKListener.DtmfInfoListener,
        SIPSDKListener.MessageListener,
        SIPSDKListener.MessageStateListener,
        SIPSDKListener.IncomingCallListener,
        SIPSDKListener.FindIncomingListener,
        SIPSDKListener.CallStateListener,
        SIPSDKListener.ExpireWarningCallbackListener,
        SIPSDKListener.ActivityCheckCallbackListener,
        SIPSDKFTListener.FTRequestListener,
        SIPSDKFTListener.FTRequestResultListener,
        SIPSDKFTListener.FTOfferListener,
        SIPSDKFTListener.FTProgressListener,
        SIPSDKFTListener.FTCompleteListener,
        CameraStateChangeCallback {
    private final Handler handler = new Handler(Looper.getMainLooper());

    // FT 进度节流状态：进度回调按块高频触发，转发前按 150ms 合并（见 onProgress）。
    private long lastFTProgressMs = 0;
    private long lastFTProgressId = -1L;

    private static class Instance {
        private static final SIPManage instance = new SIPManage();
    }

    public static SIPManage instance() {
        return Instance.instance;
    }

    public void init(Context context,
                     String baseUrl,
                     String clientId,
                     String clientSecret,
                     SIPSDKConfig config,
                     SIPSDKMediaConfig mediaConfig) {
        //注册摄像头状态监听
        CameraHandle.instance().addStateChangeCallback(this);
        //注册SDK回调
        SIPSDK.addListener(this);
        //注册文件传输回调
        SIPSDK.addFTListener(this);
        //初始化SDK
        SIPSDK.init(context, baseUrl, clientId, clientSecret, config, mediaConfig);
    }

    public void initToken(
            String token,
            String clientId,
            String clientSecret,
            SIPSDKConfig config,
            SIPSDKMediaConfig mediaConfig) {
        //注册摄像头状态监听
        CameraHandle.instance().addStateChangeCallback(this);
        //注册SDK回调
        SIPSDK.addListener(this);
        //注册文件传输回调
        SIPSDK.addFTListener(this);
        //初始化SDK
        SIPSDK.initToken(token, clientId, clientSecret, config, mediaConfig);
    }

    @Override
    public void onStateChange(boolean runing) {
        Map<String, Object> map = new HashMap<>();
        map.put("state", runing);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onCameraStateChange", map);
        });
    }

    @Override
    public void onExpireWarning(long expireTime, long currentTime) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("expireTime", expireTime);
        payload.put("currentTime", currentTime);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onExpireWarning", payload);
        });
    }

    @Override
    public void onRegistryState(int code) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("state", code);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onRegistrarState", payload);
        });
    }

    @Override
    public void onInitCompleted(int state, String msg) {
        Map<String, Object> map = new HashMap<>();
        map.put("state", state);
        map.put("message", msg);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onInitCompleted", map);
        });
    }

    @Override
    public void onIncomingCall(SIPSDKCallParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("callType", param.callType);
        payload.put("username", param.username);
        payload.put("remoteIp", param.remoteIp);
        payload.put("headers", param.headers);
        payload.put("callUuid", String.valueOf(param.callUuid));
        payload.put("transmitVideo", param.transmitVideo);
        payload.put("transmitSound", param.transmitSound);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onIncomingCall", payload);
        });
    }

    @Override
    public int onFindIncoming(SIPSDKFindIncomingParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("currentType", param.currentType);
        payload.put("transportType", param.transportType);
        payload.put("transportName", param.transportName);
        payload.put("toDomain", param.toDomain);
        payload.put("toUsername", param.toUsername);
        payload.put("fromDomain", param.fromDomain);
        payload.put("fromUsername", param.fromUsername);
        payload.put("requestDomain", param.requestDomain);
        payload.put("requestUsername", param.requestUsername);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onFindIncoming", payload);
        });
        return param.currentType;
    }

    @Override
    public void onCallState(SIPSDKCallStatusParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("state", param.state);
        payload.put("callUuid", String.valueOf(param.callUuid));
        payload.put("lastStatus", param.lastStatus);
        payload.put("lastStatusText", param.lastStatusText);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onCallState", payload);
        });
    }

    @Override
    public void onDtmfInfo(SIPSDKDtmfInfoParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("callUuid", String.valueOf(param.callUuid));
        payload.put("dtmfInfoType", param.dtmfInfoType);
        payload.put("contentType", param.contentType);
        payload.put("content", param.content);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onDtmfInfo", payload);
        });
    }

    @Override
    public void onMessage(SIPSDKMessageParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("messageType", param.messageType);
        payload.put("username", param.username);
        payload.put("remoteIp", param.remoteIp);
        payload.put("content", param.content);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onMessage", payload);
        });
    }

    @Override
    public void onMessageState(int state, SIPSDKMessageParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("state", state);
        Map<String, Object> message = new HashMap<>();
        message.put("messageType", param.messageType);
        message.put("username", param.username);
        message.put("remoteIp", param.remoteIp);
        message.put("content", param.content);
        payload.put("message", message);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onMessageState", payload);
        });
    }

    @Override
    public void onActivityCheck() {
        Map<String, Object> payload = new HashMap<>();
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onActivityCheck", payload);
        });
    }

    // ---- 文件传输（FT） ----

    private Map<String, Object> ftFileMetaMap(com.sip.sdk.entity.SIPSDKFTFileMeta file) {
        Map<String, Object> fileMap = new HashMap<>();
        if (file == null) {
            fileMap.put("name", "");
            fileMap.put("size", 0L);
            fileMap.put("extra", "");
            return fileMap;
        }
        fileMap.put("name", file.name);
        fileMap.put("size", file.size);
        fileMap.put("extra", file.extra);
        return fileMap;
    }

    @Override
    public void onOffer(SIPSDKFTOfferParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("ftId", param.ftId);
        payload.put("accUuid", param.accUuid);
        payload.put("username", param.username);
        payload.put("remoteIp", param.remoteIp);
        payload.put("file", ftFileMetaMap(param.file));
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onFTOffer", payload);
        });
    }

    @Override
    public void onRequest(SIPSDKFTRequestInfo info) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("reqId", info.reqId);
        payload.put("accUuid", info.accUuid);
        payload.put("username", info.username);
        payload.put("remoteIp", info.remoteIp);
        payload.put("file", ftFileMetaMap(info.file));
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onFTRequest", payload);
        });
    }

    @Override
    public void onRequestResult(long reqId, boolean ok, String reason) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("reqId", reqId);
        payload.put("ok", ok);
        payload.put("reason", reason);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onFTRequestResult", payload);
        });
    }

    @Override
    public void onProgress(SIPSDKFTProgress progress) {
        // 进度回调按块触发（1.5MB≈数百~上千次），且 Dart 侧当前只把它当一次
        // 「攒够 minBytes 就边传边播」的触发信号，不展示进度条；若全量经主线程
        // handler.post + MethodChannel 转发，会往主线程灌几百次跨 isolate 往返，
        // 明显拉高 CPU 并卡 UI。这里按 150ms 合并，一次传输最多转发约十次。
        // （新会话首个事件不受节流限制，保证起始进度能及时到达。）
        long now = System.currentTimeMillis();
        if (now - lastFTProgressMs < 150 && progress.ftId == lastFTProgressId) {
            return;
        }
        lastFTProgressMs = now;
        lastFTProgressId = progress.ftId;
        Map<String, Object> payload = new HashMap<>();
        payload.put("ftId", progress.ftId);
        payload.put("state", progress.state);
        payload.put("bytesTotal", progress.bytesTotal);
        payload.put("bytesDone", progress.bytesDone);
        payload.put("percent", progress.percent);
        payload.put("activeSessions", progress.activeSessions);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onFTProgress", payload);
        });
    }

    @Override
    public void onComplete(SIPSDKFTCompleteParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("ftId", param.ftId);
        payload.put("role", param.role);
        payload.put("error", param.error);
        payload.put("bytesTransferred", param.bytesTransferred);
        payload.put("elapsedMs", param.elapsedMs);
        payload.put("fileName", param.fileName);
        payload.put("savePath", param.savePath);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onFTComplete", payload);
        });
    }
}
