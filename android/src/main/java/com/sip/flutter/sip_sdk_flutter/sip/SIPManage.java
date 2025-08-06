package com.sip.flutter.sip_sdk_flutter.sip;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraHandle;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraStateChangeCallback;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.entity.SIPSDKCallParam;
import com.sip.sdk.entity.SIPSDKConfig;
import com.sip.sdk.entity.SIPSDKDtmfInfoParam;
import com.sip.sdk.entity.SIPSDKMediaConfig;
import com.sip.sdk.entity.SIPSDKMessageParam;
import com.sip.sdk.i.SIPSDKListener;

import java.util.HashMap;
import java.util.Map;

public class SIPManage implements SIPSDKListener.InitCompletedListener,
        SIPSDKListener.RegistryStateListener,
        SIPSDKListener.DtmfInfoListener,
        SIPSDKListener.MessageListener,
        SIPSDKListener.MessageStateListener,
        SIPSDKListener.IncomingCallListener,
        SIPSDKListener.CallStateListener,
        SIPSDKListener.ExpireWarningCallbackListener,
        CameraStateChangeCallback {
    private final Handler handler = new Handler(Looper.getMainLooper());

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
        //初始化SDK
        SIPSDK.init(context, baseUrl, clientId, clientSecret, config, mediaConfig);
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
        payload.put("callUUID", String.valueOf(param.callUuid));
        payload.put("transmitVideo", param.transmitVideo);
        payload.put("transmitSound", param.transmitSound);
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onIncomingCall", payload);
        });
    }

    @Override
    public void onCallState(long callUuid, int state) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("state", state);
        payload.put("callUUID", String.valueOf(callUuid));
        handler.post(() -> {
            SipSdkFlutterPlugin.channel.invokeMethod("onCallState", payload);
        });
    }

    @Override
    public void onDtmfInfo(SIPSDKDtmfInfoParam param) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("callUUID", String.valueOf(param.callUuid));
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
}
