package com.sip.flutter.sip_sdk_flutter;

import static com.sip.sdk.entity.SDKConstants.SDK_DTMF_INFO_TYPE;

import android.annotation.SuppressLint;
import android.content.Context;

import androidx.annotation.NonNull;

import com.openh264.entity.EncoderConfig;
import com.sip.flutter.sip_sdk_flutter.codes.H264CodecImpl;
import com.sip.flutter.sip_sdk_flutter.sip.SIPManage;
import com.sip.flutter.sip_sdk_flutter.utils.MapUtils;
import com.sip.flutter.sip_sdk_flutter.utils.audio.AudioHandle;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraHandle;
import com.sip.flutter.sip_sdk_flutter.view.VideoComponentFactory;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.entity.SIPSDKConfig;
import com.sip.sdk.entity.SIPSDKLocalConfig;
import com.sip.sdk.entity.SIPSDKMediaConfig;
import com.sip.sdk.entity.SIPSDKMediaH264Fmtp;
import com.sip.sdk.entity.SIPSDKRegistrarConfig;
import com.sip.sdk.entity.SIPSDKStunConfig;
import com.sip.sdk.entity.SIPSDKTurnConfig;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * SipSdkFlutterPlugin
 */
public class SipSdkFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private FlutterPluginBinding flutterPluginBinding;
    public static MethodChannel channel;

    @SuppressLint("StaticFieldLeak")
    public static Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding;
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "sip_sdk_flutter");
        channel.setMethodCallHandler(this);
        SipSdkFlutterPlugin.context = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.flutterPluginBinding
                .getPlatformViewRegistry()
                .registerViewFactory(
                        "com.sip.flutter/VideoComponentView", new VideoComponentFactory(binding.getActivity()));
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        context = null;
        this.flutterPluginBinding = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("initSDK")) {
            initSDK(call.arguments(), result);
        } else if (call.method.equals("registrar")) {
            registrar(call.arguments(), result);
        } else if (call.method.equals("unRegistrar")) {
            unRegistrar(call.arguments(), result);
        } else if (call.method.equals("cameraOpen")) {
            cameraOpen(call.arguments(), result);
        } else if (call.method.equals("cameraClose")) {
            cameraClose(call.arguments(), result);
        } else if (call.method.equals("call")) {
            call(call.arguments(), result);
        } else if (call.method.equals("callIP")) {
            callIP(call.arguments(), result);
        } else if (call.method.equals("answer")) {
            answer(call.arguments(), result);
        } else if (call.method.equals("sendDtmfInfo")) {
            sendDtmfInfo(call.arguments(), result);
        } else if (call.method.equals("sendMessage")) {
            sendMessage(call.arguments(), result);
        } else if (call.method.equals("sendMessageIP")) {
            sendMessageIP(call.arguments(), result);
        } else if (call.method.equals("hangup")) {
            hangup(call.arguments(), result);
        } else if (call.method.equals("dump")) {
            dump(call.arguments(), result);
        } else if (call.method.equals("destroy")) {
            destroy(call.arguments(), result);
        } else if (call.method.equals("handleIpChange")) {
            handleIpChange(call.arguments(), result);
        } else if (call.method.equals("isMute")) {
            isMute(call.arguments(), result);
        } else if (call.method.equals("setMute")) {
            setMute(call.arguments(), result);
        } else if (call.method.equals("isSpeaker")) {
            isSpeaker(call.arguments(), result);
        } else if (call.method.equals("setSpeaker")) {
            setSpeaker(call.arguments(), result);
        } else {
            result.notImplemented();
        }
    }

    public static String mapToJson(Map<String, Object> map) {
        if (map == null || map.isEmpty()) {
            return "{}";  // 返回空的 JSON 对象
        }

        StringBuilder jsonBuilder = new StringBuilder();
        jsonBuilder.append("{");

        Set<Map.Entry<String, Object>> entrySet = map.entrySet();
        boolean first = true;

        for (Map.Entry<String, Object> entry : entrySet) {
            if (!first) {
                jsonBuilder.append(", ");
            }
            first = false;

            String key = entry.getKey();
            Object value = entry.getValue();

            jsonBuilder.append("\"")
                    .append(key)
                    .append("\": ");

            if (value instanceof String) {
                jsonBuilder.append("\"")
                        .append(value)
                        .append("\"");
            } else if (value instanceof Number || value instanceof Boolean) {
                jsonBuilder.append(value);
            } else if (value == null) {
                jsonBuilder.append("null");
            } else {
                jsonBuilder.append(value.toString());  // 对于其他类型，直接调用其 toString()
            }
        }

        jsonBuilder.append("}");
        return jsonBuilder.toString();
    }


    private void initSDK(Map<String, Object> args, MethodChannel.Result result) {
        Map<String, Object> stunDict = MapUtils.getMap(args, "stunConfig");
        SIPSDKStunConfig stunConfig = null;
        if (stunDict != null) {
            List<String> servers = MapUtils.get(stunDict, "servers", new ArrayList<>());
            boolean enableIPv6 = MapUtils.get(stunDict, "enableIPv6", false);
            stunConfig = new SIPSDKStunConfig();
            stunConfig.count = servers.size();
            stunConfig.servers = servers;
            stunConfig.enableIpv6 = enableIPv6;
        }

        Map<String, Object> mediaDict = MapUtils.getMap(args, "mediaConfig");
        SIPSDKMediaConfig mediaConfig = new SIPSDKMediaConfig();
        if (mediaDict != null) {
            mediaConfig.audioClockRate = MapUtils.get(mediaDict, "audioClockRate", 16000);
            mediaConfig.micGain = MapUtils.get(mediaDict, "micGain", 1.0f);
            mediaConfig.speakerGain = MapUtils.get(mediaDict, "speakerGain", 1.0f);
            mediaConfig.nsEnable = MapUtils.get(mediaDict, "nsEnable", true);
            mediaConfig.agcEnable = MapUtils.get(mediaDict, "agcEnable", true);
            mediaConfig.aecEnable = MapUtils.get(mediaDict, "aecEnable", true);
            mediaConfig.aecEliminationTime = MapUtils.get(mediaDict, "aecEliminationTime", (short) 30);

            Map<String, Object> decodeConfig = MapUtils.get(mediaDict, "decodeConfig", new HashMap<>());
            mediaConfig.decodeMaxWidth = MapUtils.get(decodeConfig, "maxWidth", 1920);
            mediaConfig.decodeMaxHeight = MapUtils.get(decodeConfig, "maxHeight", 1080);
            mediaConfig.notEnableDecode = !MapUtils.get(decodeConfig, "enable", true);
            mediaConfig.combinSpsPpsIdr = MapUtils.get(decodeConfig, "combinSpsPpsIdr", true);

            Map<String, Object> encodeConfig = MapUtils.get(mediaDict, "encodeConfig", new HashMap<>());
            mediaConfig.notEnableEncode = !MapUtils.get(encodeConfig, "enable", true);
            H264CodecImpl.econfig.frameSkip = MapUtils.get(encodeConfig, "frameSkip", true);
            H264CodecImpl.econfig.rcMode = MapUtils.get(encodeConfig, "rcMode", EncoderConfig.RC_BITRATE_MODE);
            H264CodecImpl.econfig.fps = MapUtils.get(encodeConfig, "fps", 15);
            H264CodecImpl.econfig.bps = MapUtils.get(encodeConfig, "bps", 512000);
            H264CodecImpl.econfig.minBps = MapUtils.get(encodeConfig, "minBps", 256000);
            H264CodecImpl.econfig.maxBps = MapUtils.get(encodeConfig, "maxBps", 1024000);
            H264CodecImpl.econfig.qp = MapUtils.get(encodeConfig, "qp", 25);

            Map<String, Object> h264Fmtp = MapUtils.get(mediaDict, "h264Fmtp", new HashMap<>());
            String profileLevelId = MapUtils.get(h264Fmtp, "profileLevelId", null);
            String packetizationMode = MapUtils.get(h264Fmtp, "packetizationMode", null);
            if (profileLevelId != null && !profileLevelId.isEmpty() && packetizationMode != null && !packetizationMode.isEmpty()) {
                if (mediaConfig.h264Fmtp == null) {
                    mediaConfig.h264Fmtp = new SIPSDKMediaH264Fmtp();
                }
                mediaConfig.h264Fmtp.profileLevelId = profileLevelId;
                mediaConfig.h264Fmtp.packetizationMode = packetizationMode;
            }
        }

        SIPSDKConfig config = new SIPSDKConfig();
        config.port = MapUtils.get(args, "port", 58581);
        config.logLevel = MapUtils.get(args, "logLevel", 4);
        config.userAgent = MapUtils.get(args, "userAgent", "");
        config.workerThreadCount = MapUtils.get(args, "workerThreadCount", 1);
        config.videoEnable = MapUtils.get(args, "enableVideo", true);
        config.videoOutAutoTransmit = MapUtils.get(args, "videoOutAutoTransmit", true);
        config.allowMultipleConnections = MapUtils.get(args, "allowMultipleConnections", false);
        config.domainNameDirectRegistrar = MapUtils.get(args, "domainNameDirectRegistrar", false);
        config.doesItSupportBroadcast = MapUtils.get(args, "doesItSupportBroadcast", false);
        config.stunConfig = stunConfig;
        String baseUrl = MapUtils.get(args, "baseUrl", "");
        String clientId = MapUtils.get(args, "clientId", "");
        String clientSecret = MapUtils.get(args, "clientSecret", "");
        SIPManage.instance().init(context, baseUrl, clientId, clientSecret, config, mediaConfig);
        result.success(null);
    }

    private void registrar(Map<String, Object> args, MethodChannel.Result result) {
        Map<String, Object> localDict = MapUtils.getMap(args, "localConfig");
        SIPSDKLocalConfig localConfig = null;
        if (localDict != null) {
            localConfig = new SIPSDKLocalConfig();
            localConfig.username = MapUtils.get(localDict, "username", null);
            localConfig.proxy = MapUtils.get(localDict, "proxy", null);
            localConfig.proxyPort = MapUtils.get(localDict, "proxyPort", 0);
            localConfig.enableStreamControl = MapUtils.get(localDict, "enableStreamControl", false);
            localConfig.streamElapsed = MapUtils.get(localDict, "streamElapsed", 0);
            localConfig.startKeyframeCount = MapUtils.get(localDict, "startKeyframeCount", 120);
            localConfig.startKeyframeInterval = MapUtils.get(localDict, "startKeyframeInterval", 1000);
        }

        Map<String, Object> turnDict = MapUtils.getMap(args, "turnConfig");
        SIPSDKTurnConfig turnConfig = null;
        if (turnDict != null) {
            turnConfig = new SIPSDKTurnConfig();
            turnConfig.enable = MapUtils.get(turnDict, "enable", false);
            turnConfig.server = MapUtils.get(turnDict, "server", null);
            turnConfig.realm = MapUtils.get(turnDict, "realm", null);
            turnConfig.username = MapUtils.get(turnDict, "username", null);
            turnConfig.password = MapUtils.get(turnDict, "password", null);
        }

        Map<String, String> headers = new HashMap<>();
        Map<String, Object> rawHeaders = MapUtils.getMap(args, "headers");
        if (rawHeaders != null) {
            for (Map.Entry<String, Object> entry : rawHeaders.entrySet()) {
                if (entry.getValue() instanceof String) {
                    headers.put(entry.getKey(), (String) entry.getValue());
                }
            }
        }

        SIPSDKRegistrarConfig config = new SIPSDKRegistrarConfig();
        config.domain = MapUtils.get(args, "domain", null);
        config.username = MapUtils.get(args, "username", null);
        config.password = MapUtils.get(args, "password", null);
        config.transport = MapUtils.get(args, "transport", null);
        config.serverAddr = MapUtils.get(args, "serverAddr", null);
        config.serverPort = MapUtils.get(args, "serverPort", 5060);
        config.proxy = MapUtils.get(args, "proxy", null);
        config.proxyPort = MapUtils.get(args, "proxyPort", 5060);
        config.enableStreamControl = MapUtils.get(args, "enableStreamControl", false);
        config.streamElapsed = MapUtils.get(args, "streamElapsed", 0);
        config.startKeyframeCount = MapUtils.get(args, "startKeyframeCount", 120);
        config.startKeyframeInterval = MapUtils.get(args, "startKeyframeInterval", 1000);
        config.headers = headers;
        config.turnConfig = turnConfig;

        SIPSDK.registrarAccount(config);
        result.success(null);
    }

    /**
     * 解除注册到服务器
     */
    private void unRegistrar(Map<String, Object> args, MethodChannel.Result result) {
        SIPSDK.unRegistrar();
        result.success(null);
    }

    /**
     * 打开摄像头
     */
    private void cameraOpen(Map<String, Object> args, MethodChannel.Result result) {
        int index = MapUtils.get(args, "index", null);
        int width = MapUtils.get(args, "width", null);
        int height = MapUtils.get(args, "height", null);
        CameraHandle.instance().open(index, width, height);
        result.success(null);
    }

    /**
     * 关闭摄像头
     */
    private void cameraClose(Map<String, Object> args, MethodChannel.Result result) {
        CameraHandle.instance().close();
        result.success(null);
    }

    private void call(Map<String, Object> args, MethodChannel.Result result) {
        String username = MapUtils.get(args, "username", null);
        Map<String, String> headers = new HashMap<>();
        Map<String, Object> rawHeaders = MapUtils.getMap(args, "headers");
        if (rawHeaders != null) {
            for (Map.Entry<String, Object> entry : rawHeaders.entrySet()) {
                if (entry.getValue() instanceof String) {
                    headers.put(entry.getKey(), (String) entry.getValue());
                }
            }
        }
        long uuid = SIPSDK.call(username, headers);
        result.success(String.valueOf(uuid));
    }

    private void callIP(Map<String, Object> args, MethodChannel.Result result) {
        String ip = MapUtils.get(args, "ip", null);
        Map<String, String> headers = new HashMap<>();
        Map<String, Object> rawHeaders = MapUtils.getMap(args, "headers");
        if (rawHeaders != null) {
            for (Map.Entry<String, Object> entry : rawHeaders.entrySet()) {
                if (entry.getValue() instanceof String) {
                    headers.put(entry.getKey(), (String) entry.getValue());
                }
            }
        }
        long uuid = SIPSDK.callIP(ip, headers);
        result.success(String.valueOf(uuid));
    }

    private void answer(Map<String, Object> args, MethodChannel.Result result) {
        int code = MapUtils.get(args, "200", 200);
        long callUUID = MapUtils.get(args, "callUUID", 0);
        SIPSDK.answer(code, callUUID);
        result.success(null);
    }

    private void sendDtmfInfo(Map<String, Object> args, MethodChannel.Result result) {
        long callUUID = MapUtils.get(args, "callUUID", 0);
        int dtmfInfoType = MapUtils.get(args, "dtmfInfoType", SDK_DTMF_INFO_TYPE);
        String content = MapUtils.get(args, "content", null);
        String contentType = MapUtils.get(args, "contentType", null);
        SIPSDK.sendDtmfInfo(dtmfInfoType, contentType, content);
        result.success(null);
    }

    private void sendMessage(Map<String, Object> args, MethodChannel.Result result) {
        String username = MapUtils.get(args, "username", null);
        String content = MapUtils.get(args, "content", null);
        SIPSDK.sendMessage(username, content);
        result.success(null);
    }

    private void sendMessageIP(Map<String, Object> args, MethodChannel.Result result) {
        String ip = MapUtils.get(args, "ip", null);
        String content = MapUtils.get(args, "content", null);
        SIPSDK.sendMessageIP(ip, content);
        result.success(null);
    }

    private void hangup(Map<String, Object> args, MethodChannel.Result result) {
        int code = MapUtils.get(args, "code", 487);
        long callUUID = MapUtils.get(args, "callUUID", 0);
        if (callUUID == 0) {
            SIPSDK.hangup(code);
        } else {
            SIPSDK.hangupWithUuid(code, callUUID);
        }
        result.success(null);
    }

    /**
     * 打印SDK信息，包括所有内存使用信息
     */
    private void dump(Map<String, Object> args, MethodChannel.Result result) {
        SIPSDK.dump();
        result.success(null);
    }

    private void destroy(Map<String, Object> args, MethodChannel.Result result) {
        SIPSDK.destroy();
        result.success(null);
    }

    private void handleIpChange(Map<String, Object> args, MethodChannel.Result result) {
        SIPSDK.handleIpChange();
        result.success(null);
    }

    private void isMute(Map<String, Object> args, MethodChannel.Result result) {
        boolean mute = AudioHandle.instance().isMicrophoneMute();
        result.success(mute);
    }

    private void setMute(Map<String, Object> args, MethodChannel.Result result) {
        boolean mute = MapUtils.get(args, "mute", false);
        AudioHandle.instance().microphoneMuteSwitch(mute);
        result.success(null);
    }

    private void isSpeaker(Map<String, Object> args, MethodChannel.Result result) {
        boolean speaker = AudioHandle.instance().isSpeakerphoneOn();
        result.success(speaker);
    }

    private void setSpeaker(Map<String, Object> args, MethodChannel.Result result) {
        boolean speaker = MapUtils.get(args, "speaker", true);
        AudioHandle.instance().speakerSwitch(speaker);
        result.success(null);
    }
}
