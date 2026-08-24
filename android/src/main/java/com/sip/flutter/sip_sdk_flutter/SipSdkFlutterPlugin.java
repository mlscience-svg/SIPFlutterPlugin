package com.sip.flutter.sip_sdk_flutter;

import static com.sip.sdk.entity.SDKConstants.SDK_DTMF_INFO_TYPE;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Dialog;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.MediaScannerConnection;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.util.Size;
import android.view.Gravity;
import android.widget.FrameLayout;
import android.widget.MediaController;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.VideoView;

import androidx.annotation.NonNull;

import com.openh264.entity.EncoderConfig;
import com.sip.flutter.sip_sdk_flutter.codes.H264CodecImpl;
import com.sip.flutter.sip_sdk_flutter.sip.SIPManage;
import com.sip.flutter.sip_sdk_flutter.utils.MapUtils;
import com.sip.flutter.sip_sdk_flutter.utils.audio.AudioHandle;
import com.sip.flutter.sip_sdk_flutter.utils.audio.AudioPlayer;
import com.sip.flutter.sip_sdk_flutter.utils.audio.AudioRecorder;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraHandle;
import com.sip.flutter.sip_sdk_flutter.utils.media.CallMediaRecorder;
import com.sip.flutter.sip_sdk_flutter.view.VideoComponentFactory;
import com.sip.flutter.sip_sdk_flutter.view.VideoComponentView;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.entity.SDKConstants;
import com.sip.sdk.entity.SIPSDKCallParam;
import com.sip.sdk.entity.SIPSDKConfig;
import com.sip.sdk.entity.SIPSDKDtmfInfoParam;
import com.sip.sdk.entity.SIPSDKLocalConfig;
import com.sip.sdk.entity.SIPSDKMediaConfig;
import com.sip.sdk.entity.SIPSDKMediaH264Fmtp;
import com.sip.sdk.entity.SIPSDKMessageParam;
import com.sip.sdk.entity.SIPSDKRegistrarConfig;
import com.sip.sdk.entity.SIPSDKStunConfig;
import com.sip.sdk.entity.SIPSDKTurnConfig;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
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

    /** 当前宿主 Activity，用于全屏播放视频。 */
    private Activity currentActivity;

    /** App 公共根目录名 = App 显示名「Parsian Tasvir」去空格。相册 / lastframe / callrecord 都在它下面。 */
    private static final String APP_ROOT = "ParsianTasvir";

    /** 相册媒体根目录（相对 APP_ROOT）。 */
    private static final String MEDIA_ROOT = "Doorbell";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding;
        if (channel == null) {
            channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "sip_sdk_flutter");
            channel.setMethodCallHandler(this);
        }
        if (context == null) {
            context = flutterPluginBinding.getApplicationContext();
        }
        H264CodecImpl.addRawListener(CallMediaRecorder.instance());
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        currentActivity = binding.getActivity();
        this.flutterPluginBinding
                .getPlatformViewRegistry()
                .registerViewFactory(
                        "com.sip.flutter/VideoComponentView", new VideoComponentFactory(binding.getActivity()));
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        currentActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        currentActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        currentActivity = null;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        H264CodecImpl.removeRawListener(CallMediaRecorder.instance());
        channel.setMethodCallHandler(null);
        channel = null;
        context = null;
        this.flutterPluginBinding = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("initSDK")) {
            initSDK(call.arguments(), result);
        } else if (call.method.equals("initToken")) {
            this.initToken(call.arguments(), result);
        } else if (call.method.equals("localAccount")) {
            this.localAccount(call.arguments(), result);
        } else if (call.method.equals("remoteAccount")) {
            this.remoteAccount(call.arguments(), result);
        } else if (call.method.equals("delRemoteAccount")) {
            this.delRemoteAccount(call.arguments(), result);
        } else if (call.method.equals("cameraOpen")) {
            cameraOpen(call.arguments(), result);
        } else if (call.method.equals("cameraClose")) {
            cameraClose(call.arguments(), result);
        } else if (call.method.equals("captureSnapshot")) {
            captureSnapshot(call.arguments(), result);
        } else if (call.method.equals("saveSnapshotToDocuments")) {
            saveSnapshotToDocuments(call.arguments(), result);
        } else if (call.method.equals("startVideoRecording")) {
            startVideoRecording(call.arguments(), result);
        } else if (call.method.equals("stopVideoRecording")) {
            stopVideoRecording(call.arguments(), result);
        } else if (call.method.equals("queryMediaFiles")) {
            queryMediaFiles(call.arguments(), result);
        } else if (call.method.equals("migrateMediaToAppRoot")) {
            migrateMediaToAppRoot(result);
        } else if (call.method.equals("loadMediaThumbnail")) {
            loadMediaThumbnail(call.arguments(), result);
        } else if (call.method.equals("loadMediaBytes")) {
            loadMediaBytes(call.arguments(), result);
        } else if (call.method.equals("playMediaVideo")) {
            playMediaVideo(call.arguments(), result);
        } else if (call.method.equals("saveMediaToAlbum")) {
            saveMediaToAlbum(call.arguments(), result);
        } else if (call.method.equals("deleteMediaFiles")) {
            deleteMediaFiles(call.arguments(), result);
        } else if (call.method.equals("call")) {
            call(call.arguments(), result);
        } else if (call.method.equals("answer")) {
            answer(call.arguments(), result);
        } else if (call.method.equals("sendDtmfInfo")) {
            sendDtmfInfo(call.arguments(), result);
        } else if (call.method.equals("sendMessage")) {
            sendMessage(call.arguments(), result);
        } else if (call.method.equals("hangup")) {
            hangup(call.arguments(), result);
        } else if (call.method.equals("dump")) {
            dump(call.arguments(), result);
        } else if (call.method.equals("destroy")) {
            destroy(call.arguments(), result);
        } else if (call.method.equals("handleIpChange")) {
            handleIpChange(call.arguments(), result);
        } else if (call.method.equals("startRecording")) {
            startRecording(call.arguments(), result);
        } else if (call.method.equals("stopRecording")) {
            stopRecording(call.arguments(), result);
        } else if (call.method.equals("startPlaying")) {
            startPlaying(call.arguments(), result);
        } else if (call.method.equals("stopPlaying")) {
            stopPlaying(call.arguments(), result);
        } else if (call.method.equals("isMute")) {
            isMute(call.arguments(), result);
        } else if (call.method.equals("setMute")) {
            setMute(call.arguments(), result);
        } else if (call.method.equals("isSpeaker")) {
            isSpeaker(call.arguments(), result);
        } else if (call.method.equals("setSpeaker")) {
            setSpeaker(call.arguments(), result);
        } else if (call.method.equals("setImageRatio")) {
            setImageRatio(call.arguments(), result);
        } else if (call.method.equals("clearVideo")) {
            clearVideo(call.arguments(), result);
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
            mediaConfig.audioOnlyCallConfirmed = MapUtils.get(mediaDict, "audioOnlyCallConfirmed", true);
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

        AudioRecorder.instance().setSampleRate(mediaConfig.audioClockRate);
        AudioPlayer.instance().setSampleRate(mediaConfig.audioClockRate);

        SIPSDKConfig config = new SIPSDKConfig();
        config.logLevel = MapUtils.get(args, "logLevel", 4);
        config.port = MapUtils.get(args, "port", 5060);
        config.userAgent = MapUtils.get(args, "userAgent", "");
        config.workerThreadCount = MapUtils.get(args, "workerThreadCount", 1);
        config.updateRoute = MapUtils.get(args, "updateRoute", false);
        config.videoEnable = MapUtils.get(args, "enableVideo", true);
        config.videoOutAutoTransmit = MapUtils.get(args, "videoOutAutoTransmit", true);
        config.allowMultipleConnections = MapUtils.get(args, "allowMultipleConnections", false);
        config.domainNameDirectRegistrar = MapUtils.get(args, "domainNameDirectRegistrar", false);
        config.doesItSupportBroadcast = MapUtils.get(args, "doesItSupportBroadcast", false);
        config.customSessionName = MapUtils.get(args, "customSessionName", null);
        config.localCallUpdateTime = MapUtils.get(args, "localCallUpdateTime", 60);
        config.tcpKeepAliveInterval = MapUtils.get(args, "tcpKeepAliveInterval", 60);
        config.tcpDisconnectOnSilence = MapUtils.get(args, "tcpDisconnectOnSilence", false);
        config.stunConfig = stunConfig;
        String baseUrl = MapUtils.get(args, "baseUrl", "");
        String clientId = MapUtils.get(args, "clientId", "");
        String clientSecret = MapUtils.get(args, "clientSecret", "");
        SIPManage.instance().init(context, baseUrl, clientId, clientSecret, config, mediaConfig);
        result.success(null);
    }

    private void initToken(Map<String, Object> args, MethodChannel.Result result) {
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
            mediaConfig.audioOnlyCallConfirmed = MapUtils.get(mediaDict, "audioOnlyCallConfirmed", true);
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

        AudioRecorder.instance().setSampleRate(mediaConfig.audioClockRate);
        AudioPlayer.instance().setSampleRate(mediaConfig.audioClockRate);

        SIPSDKConfig config = new SIPSDKConfig();
        config.logLevel = MapUtils.get(args, "logLevel", 4);
        config.port = MapUtils.get(args, "port", 5060);
        config.userAgent = MapUtils.get(args, "userAgent", "");
        config.workerThreadCount = MapUtils.get(args, "workerThreadCount", 1);
        config.updateRoute = MapUtils.get(args, "updateRoute", false);
        config.videoEnable = MapUtils.get(args, "enableVideo", true);
        config.videoOutAutoTransmit = MapUtils.get(args, "videoOutAutoTransmit", true);
        config.allowMultipleConnections = MapUtils.get(args, "allowMultipleConnections", false);
        config.domainNameDirectRegistrar = MapUtils.get(args, "domainNameDirectRegistrar", false);
        config.doesItSupportBroadcast = MapUtils.get(args, "doesItSupportBroadcast", false);
        config.customSessionName = MapUtils.get(args, "customSessionName", null);
        config.localCallUpdateTime = MapUtils.get(args, "localCallUpdateTime", 60);
        config.tcpKeepAliveInterval = MapUtils.get(args, "tcpKeepAliveInterval", 60);
        config.tcpDisconnectOnSilence = MapUtils.get(args, "tcpDisconnectOnSilence", false);
        config.stunConfig = stunConfig;
        String token = MapUtils.get(args, "token", "");
        String clientId = MapUtils.get(args, "clientId", "");
        String clientSecret = MapUtils.get(args, "clientSecret", "");
        SIPManage.instance().initToken(token, clientId, clientSecret, config, mediaConfig);
        result.success(null);
    }

    private void localAccount(Map<String, Object> args, MethodChannel.Result result) {
        SIPSDKLocalConfig localConfig = new SIPSDKLocalConfig();
        localConfig.transport = MapUtils.get(args, "transport", null);
        localConfig.port = MapUtils.get(args, "port", 5060);
        localConfig.username = MapUtils.get(args, "username", null);
        localConfig.boundAddr = MapUtils.get(args, "boundAddr", null);
        localConfig.publicAddr = MapUtils.get(args, "publicAddr", null);
        localConfig.lockCodec = MapUtils.get(args, "lockCodec", 0);
        localConfig.enableStreamControl = MapUtils.get(args, "enableStreamControl", false);
        localConfig.streamElapsed = MapUtils.get(args, "streamElapsed", 0);

        SIPSDK.localAccount(localConfig);
        result.success(null);
    }

    private void remoteAccount(Map<String, Object> args, MethodChannel.Result result) {
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
        config.srtpKeying = MapUtils.get(args, "srtpKeying", false);
        config.lockCodec = MapUtils.get(args, "lockCodec", 0);
        config.enableStreamControl = MapUtils.get(args, "enableStreamControl", false);
        config.streamElapsed = MapUtils.get(args, "streamElapsed", 0);
        config.headers = headers;
        config.turnConfig = turnConfig;

        SIPSDK.remoteAccount(config);
        result.success(null);
    }

    /**
     * 解除注册到服务器
     */
    private void delRemoteAccount(Map<String, Object> args, MethodChannel.Result result) {
        SIPSDK.delRemoteAccount();
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

    private void captureSnapshot(Map<String, Object> args, MethodChannel.Result result) {
        VideoComponentView view = VideoComponentView.getCurrentInstance();
        if (view == null) {
            result.success(null);
            return;
        }
        // I420→Bitmap→PNG 编码比较耗时，放到后台线程避免阻塞 UI。
        new Thread(() -> {
            Bitmap bitmap = view.captureBitmap();
            if (bitmap == null) {
                new Handler(Looper.getMainLooper()).post(() -> result.success(null));
                return;
            }
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            new Handler(Looper.getMainLooper())
                    .post(() -> result.success(stream.toByteArray()));
        }).start();
    }

    /**
     * 截取对方视频画面并保存为 JPG 到 relativePath 指定的位置。
     * relativePath 是相对媒体根目录的完整路径（含文件名），如
     * Doorbell/<deviceId>/photo/2026/08/10/101530_123.jpg。
     * Android 10+ 通过 MediaStore 写入（USB 可见、可导出、按设备区分）；
     * Android 9 及以下直接写外部存储文件系统。
     */
    private void saveSnapshotToDocuments(Map<String, Object> args, MethodChannel.Result result) {
        String relativePath = MapUtils.get(args, "relativePath", null);
        if (relativePath == null || relativePath.isEmpty()) {
            result.success(null);
            return;
        }
        VideoComponentView view = VideoComponentView.getCurrentInstance();
        if (view == null) {
            result.success(null);
            return;
        }
        // 抓原始帧、JPEG 编码（100% 质量）和 MediaStore 写入都比较耗时，
        // 放到后台线程避免阻塞 UI，完成后回主线程回调结果。
        new Thread(() -> {
            Bitmap bitmap = view.captureBitmap();
            if (bitmap == null) {
                postResult(result, null, null);
                return;
            }
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, output);
            try {
                String path = saveToDocuments(output.toByteArray(), relativePath);
                postResult(result, path, null);
            } catch (Exception e) {
                postResult(result, null, e);
            }
        }).start();
    }

    private void postResult(MethodChannel.Result result, String path, Exception error) {
        new Handler(Looper.getMainLooper()).post(() -> {
            if (error != null) {
                result.error("SAVE_FAILED", error.getMessage(), null);
            } else {
                result.success(path);
            }
        });
    }

    private String saveToDocuments(byte[] bytes, String relativePath)
            throws IOException {
        // relativePath = "Doorbell/<deviceId>/<type>/<yyyy>/<MM>/<dd>/<file>"
        String[] parts = splitRelativePath(relativePath);
        String dirRelative = parts[0];   // "Documents/Doorbell/..."（不含文件名）
        String fileName = parts[1];
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // MediaStore.Downloads 集合只允许 Download 主目录，所以改用
            // MediaStore.Files 集合，它支持任意的标准目录（Documents 等），
            // 且会自动创建不存在的目录。
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
            values.put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg");
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, dirRelative);
            Uri uri = context.getContentResolver().insert(
                    MediaStore.Files.getContentUri("external"), values);
            if (uri == null) {
                throw new IOException("Failed to create MediaStore entry");
            }
            try (OutputStream os = context.getContentResolver().openOutputStream(uri)) {
                if (os == null) {
                    throw new IOException("Failed to open output stream");
                }
                os.write(bytes);
            }
            return uri.toString();
        } else {
            File dir = new File(Environment.getExternalStorageDirectory(), dirRelative);
            if (!dir.exists() && !dir.mkdirs()) {
                throw new IOException("Failed to create directory: " + dir);
            }
            File file = new File(dir, fileName);
            try (FileOutputStream fos = new FileOutputStream(file)) {
                fos.write(bytes);
            }
            return file.getAbsolutePath();
        }
    }

    /**
     * 把 relativePath 拆成「不含文件名的目录相对路径」和「文件名」。
     * 目录相对路径以 "Documents/" 开头，供 MediaStore.RELATIVE_PATH
     * 与 ≤API 28 的文件系统路径共用。
     */
    private String[] splitRelativePath(String relativePath) {
        int idx = relativePath.lastIndexOf('/');
        String dir = idx > 0 ? relativePath.substring(0, idx) : "";
        String fileName = idx >= 0 ? relativePath.substring(idx + 1) : relativePath;
        return new String[]{"Documents/" + dir, fileName};
    }

    /** 本次录制完成后要归档到的完整相对路径（含文件名）。 */
    private String pendingRecordRelativePath;

    private void startVideoRecording(Map<String, Object> args, MethodChannel.Result result) {
        String relativePath = MapUtils.get(args, "relativePath", null);
        if (relativePath == null || relativePath.isEmpty()) {
            result.success(null);
            return;
        }
        // 录制期间先写到 app 私有缓存，stop 时再搬到 relativePath 指定的外部存储，
        // 避免通话中断时在用户的公共目录里留下半个损坏的 mp4。
        File recordDir = new File(context.getCacheDir(), "call_recordings");
        if (recordDir.exists()) {
            File[] stale = recordDir.listFiles();
            if (stale != null) {
                for (File f : stale) {
                    f.delete();
                }
            }
        } else if (!recordDir.mkdirs()) {
            result.success(null);
            return;
        }
        String tempPath = new File(
                recordDir, "call_" + System.currentTimeMillis() + ".mp4").getAbsolutePath();
        String savedPath = CallMediaRecorder.instance().start(
                tempPath, AudioPlayer.instance().getSampleRate());
        if (savedPath == null) {
            result.success(null);
            return;
        }
        pendingRecordRelativePath = relativePath;
        result.success(savedPath);
    }

    private void stopVideoRecording(Map<String, Object> args, MethodChannel.Result result) {
        // muxer 收尾和文件搬到外部存储都比较耗时，放到后台线程。
        new Thread(() -> {
            String tempPath = CallMediaRecorder.instance().stop();
            if (tempPath == null) {
                postResult(result, null, null);
                return;
            }
            String relativePath = pendingRecordRelativePath;
            pendingRecordRelativePath = null;
            if (relativePath == null || relativePath.isEmpty()) {
                postResult(result, null, null);
                return;
            }
            try {
                String uri = writeVideoToDocuments(new File(tempPath), relativePath);
                postResult(result, uri, null);
            } catch (Exception e) {
                postResult(result, null, e);
            }
        }).start();
    }

    /**
     * 把录制的临时 mp4 流式拷贝到 relativePath 指定的外部存储位置，
     * 拷贝完成返回目标（API 29+ 为 content:// URI，API <=28 为文件路径），
     * 同时删除临时文件。大文件全程走 64KB 缓冲，不整包加载到内存。
     */
    private String writeVideoToDocuments(File source, String relativePath) throws IOException {
        if (!source.exists() || source.length() <= 0) {
            throw new IOException("Recording file is empty");
        }
        String[] parts = splitRelativePath(relativePath);
        String dirRelative = parts[0];   // "Documents/Doorbell/..."（不含文件名）
        String fileName = parts[1];
        String mimeType = "video/mp4";
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
            values.put(MediaStore.MediaColumns.MIME_TYPE, mimeType);
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, dirRelative);
            Uri uri = context.getContentResolver().insert(
                    MediaStore.Files.getContentUri("external"), values);
            if (uri == null) {
                throw new IOException("Failed to create MediaStore entry");
            }
            try (OutputStream os = context.getContentResolver().openOutputStream(uri)) {
                if (os == null) {
                    throw new IOException("Failed to open output stream");
                }
                copyFileTo(source, os);
            }
            source.delete();
            return uri.toString();
        } else {
            File dir = new File(Environment.getExternalStorageDirectory(), dirRelative);
            if (!dir.exists() && !dir.mkdirs()) {
                throw new IOException("Failed to create directory: " + dir);
            }
            File target = new File(dir, fileName);
            try (FileOutputStream fos = new FileOutputStream(target)) {
                copyFileTo(source, fos);
            }
            source.delete();
            return target.getAbsolutePath();
        }
    }

    private void copyFileTo(File source, OutputStream os) throws IOException {
        try (InputStream in = new FileInputStream(source)) {
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                os.write(buffer, 0, read);
            }
        }
    }

    /* ============================ 相册（拍照/录制视频）读取 ============================ */

    private void queryMediaFiles(Map<String, Object> args, MethodChannel.Result result) {
        // 查询 MediaStore / 遍历文件系统耗时，放到后台线程，完成后回主线程回调。
        new Thread(() -> {
            try {
                List<Map<String, Object>> list = listDoorbellMedia();
                new Handler(Looper.getMainLooper()).post(() -> result.success(list));
            } catch (Exception e) {
                new Handler(Looper.getMainLooper())
                        .post(() -> result.error("QUERY_FAILED", e.getMessage(), null));
            }
        }).start();
    }

    /** 一次性迁移旧媒体目录（Doorbell / lastframe / callrecord）到 app 公共根目录 ParsianTasvir/ 下。
     *  幂等：Q+ 按旧 RELATIVE_PATH 前缀查询，迁移后再查无匹配行；≤28 根目录已存在则跳过。 */
    private void migrateMediaToAppRoot(MethodChannel.Result result) {
        new Thread(() -> {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    migrateMediaViaMediaStore();
                } else {
                    File docs = new File(Environment.getExternalStorageDirectory(), "Documents");
                    File appRoot = new File(docs, APP_ROOT);
                    if (!appRoot.exists() && appRoot.mkdirs()) {
                        for (String sub : new String[]{MEDIA_ROOT, "lastframe", "callrecord"}) {
                            File src = new File(docs, sub);
                            if (src.exists()) {
                                src.renameTo(new File(appRoot, sub));
                            }
                        }
                    }
                }
            } catch (Exception ignore) {
                // 迁移失败不影响启动，静默忽略。
            }
            new Handler(Looper.getMainLooper()).post(() -> result.success(true));
        }).start();
    }

    /** API 29+：迁移 MediaStore 行。直接把 RELATIVE_PATH 改到新前缀在部分 Android 版本上不受支持，
     *  所以采用「拷贝字节 → 插入新行 → 删除旧行」，全版本可靠。 */
    private void migrateMediaViaMediaStore() {
        String[] oldPrefixes = {"Documents/" + MEDIA_ROOT + "/",
                "Documents/lastframe/", "Documents/callrecord/"};
        for (String oldPrefix : oldPrefixes) {
            Uri collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL);
            String[] projection = new String[]{
                    MediaStore.MediaColumns._ID,
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    MediaStore.MediaColumns.DISPLAY_NAME
            };
            String selection = MediaStore.MediaColumns.RELATIVE_PATH + " LIKE ?";
            List<Object[]> rows = new ArrayList<>(); // {旧 uri, 新 Dart 相对路径}
            try (Cursor cursor = context.getContentResolver().query(
                    collection, projection, selection,
                    new String[]{oldPrefix + "%"}, null)) {
                if (cursor == null) continue;
                int idCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID);
                int pathCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH);
                int nameCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME);
                while (cursor.moveToNext()) {
                    String relative = cursor.getString(pathCol);
                    String displayName = cursor.getString(nameCol);
                    if (relative == null || displayName == null) continue;
                    String suffix = relative.startsWith("Documents/")
                            ? relative.substring("Documents/".length()) : relative;
                    if (!suffix.endsWith("/")) suffix += "/";
                    rows.add(new Object[]{
                            ContentUris.withAppendedId(collection, cursor.getLong(idCol)),
                            APP_ROOT + "/" + suffix + displayName});
                }
            }
            for (Object[] row : rows) {
                try {
                    Uri oldUri = (Uri) row[0];
                    byte[] bytes = readMediaBytes(oldUri);
                    if (bytes == null) continue;
                    saveToDocuments(bytes, (String) row[1]);
                    context.getContentResolver().delete(oldUri, null, null);
                } catch (Exception ignore) {
                    // 单个文件迁移失败不影响其它文件，静默跳过。
                }
            }
        }
    }

    /**
     * 枚举媒体根目录（Documents/ParsianTasvir/Doorbell/）下的所有拍照 / 录制视频。
     * 每条记录包含 relativePath（统一为 Doorbell/<deviceKey>/<type>/<yyyy>/<MM>/<dd>/<file>，
     * 剥掉 app 根前缀 ParsianTasvir/，与 Dart 侧解析约定一致）
     * 和 uri（API 29+ 为 content://，否则为绝对路径），按时间倒序（新在前）。
     */
    private List<Map<String, Object>> listDoorbellMedia() {
        List<Map<String, Object>> list = new ArrayList<>();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            queryMediaStore(list);
        } else {
            File root = new File(Environment.getExternalStorageDirectory(),
                    "Documents/" + APP_ROOT + "/" + MEDIA_ROOT);
            collectMediaFiles(root, MEDIA_ROOT, list);
        }
        return list;
    }

    /** API 29+：通过 MediaStore.Files 查询，RELATIVE_PATH 自动建目录的写入方式可被直接索引。 */
    private void queryMediaStore(List<Map<String, Object>> list) {
        Uri collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL);
        String[] projection = new String[]{
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.RELATIVE_PATH,
                MediaStore.MediaColumns.DISPLAY_NAME
        };
        String selection = MediaStore.MediaColumns.RELATIVE_PATH + " LIKE ?";
        String[] selectionArgs = new String[]{"Documents/" + APP_ROOT + "/" + MEDIA_ROOT + "/%"};
        try (Cursor cursor = context.getContentResolver().query(
                collection, projection, selection, selectionArgs,
                MediaStore.MediaColumns.DATE_ADDED + " DESC")) {
            if (cursor == null) return;
            int idCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID);
            int pathCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH);
            int nameCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME);
            while (cursor.moveToNext()) {
                String relative = cursor.getString(pathCol);
                String displayName = cursor.getString(nameCol);
                if (relative == null || displayName == null || !isMediaFile(displayName)) continue;
                String rel = relative;
                if (rel.startsWith("Documents/")) {
                    rel = rel.substring("Documents/".length());
                }
                // 剥掉 app 根前缀，使 relativePath 统一为 Doorbell/<deviceKey>/<type>/...
                if (rel.startsWith(APP_ROOT + "/")) {
                    rel = rel.substring((APP_ROOT + "/").length());
                }
                // 部分设备（如 OPPO）返回的 RELATIVE_PATH 可能不带结尾斜杠，
                // 拼接文件名前补上，避免日期目录和文件名粘在一起导致解析失败。
                String fullRel = rel.endsWith("/")
                        ? rel + displayName
                        : rel + "/" + displayName;
                Uri contentUri = ContentUris.withAppendedId(collection, cursor.getLong(idCol));
                Map<String, Object> m = new HashMap<>();
                m.put("relativePath", fullRel);
                m.put("uri", contentUri.toString());
                list.add(m);
            }
        }
    }

    /** API <=28：直接遍历外部存储下的 Documents/Doorbell 目录。 */
    private void collectMediaFiles(File dir, String relativePrefix, List<Map<String, Object>> list) {
        File[] files = dir.listFiles();
        if (files == null) return;
        for (File f : files) {
            String rel = relativePrefix + "/" + f.getName();
            if (f.isDirectory()) {
                collectMediaFiles(f, rel, list);
            } else if (isMediaFile(f.getName())) {
                Map<String, Object> m = new HashMap<>();
                m.put("relativePath", rel);
                m.put("uri", f.getAbsolutePath());
                list.add(m);
            }
        }
    }

    private boolean isMediaFile(String name) {
        String n = name.toLowerCase();
        return n.endsWith(".jpg") || n.endsWith(".jpeg")
                || n.endsWith(".png") || n.endsWith(".mp4");
    }

    private void loadMediaThumbnail(Map<String, Object> args, MethodChannel.Result result) {
        String uriStr = MapUtils.get(args, "uri", null);
        int maxSize = MapUtils.get(args, "maxSize", 256);
        if (uriStr == null || uriStr.isEmpty()) {
            result.success(null);
            return;
        }
        new Thread(() -> {
            try {
                Bitmap bitmap = buildThumbnail(Uri.parse(uriStr), maxSize);
                if (bitmap == null) {
                    new Handler(Looper.getMainLooper()).post(() -> result.success(null));
                    return;
                }
                ByteArrayOutputStream output = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 85, output);
                byte[] bytes = output.toByteArray();
                new Handler(Looper.getMainLooper()).post(() -> result.success(bytes));
            } catch (Exception e) {
                new Handler(Looper.getMainLooper()).post(() -> result.success(null));
            }
        }).start();
    }

    private Bitmap buildThumbnail(Uri uri, int maxSize) throws IOException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // 图片 / 视频统一走 MediaStore 缩略图
            return context.getContentResolver().loadThumbnail(
                    uri, new Size(maxSize, maxSize), null);
        }
        String path = uri.getPath();
        if (path == null) return null;
        if (path.toLowerCase().endsWith(".mp4")) {
            // MINI_KIND 约 512px，网格展示足够
            return ThumbnailUtils.createVideoThumbnail(path, MediaStore.Images.Thumbnails.MINI_KIND);
        }
        // 图片：先读尺寸算采样率，避免整图加载
        BitmapFactory.Options opt = new BitmapFactory.Options();
        opt.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, opt);
        int sample = 1;
        while (opt.outWidth / sample > maxSize * 2 || opt.outHeight / sample > maxSize * 2) {
            sample *= 2;
        }
        opt.inJustDecodeBounds = false;
        opt.inSampleSize = sample;
        return BitmapFactory.decodeFile(path, opt);
    }

    private void loadMediaBytes(Map<String, Object> args, MethodChannel.Result result) {
        String uriStr = MapUtils.get(args, "uri", null);
        if (uriStr == null || uriStr.isEmpty()) {
            result.success(null);
            return;
        }
        new Thread(() -> {
            try {
                byte[] bytes = readMediaBytes(Uri.parse(uriStr));
                new Handler(Looper.getMainLooper()).post(() -> result.success(bytes));
            } catch (Exception e) {
                new Handler(Looper.getMainLooper()).post(() -> result.success(null));
            }
        }).start();
    }

    private byte[] readMediaBytes(Uri uri) throws IOException {
        InputStream in;
        if ("content".equals(uri.getScheme())) {
            in = context.getContentResolver().openInputStream(uri);
        } else {
            File file = new File(uri.getPath());
            if (!file.exists()) return null;
            in = new FileInputStream(file);
        }
        if (in == null) return null;
        try (InputStream stream = in) {
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = stream.read(buffer)) != -1) {
                output.write(buffer, 0, read);
            }
            return output.toByteArray();
        }
    }

    private void playMediaVideo(Map<String, Object> args, MethodChannel.Result result) {
        String uriStr = MapUtils.get(args, "uri", null);
        if (uriStr == null || uriStr.isEmpty()) {
            result.success(null);
            return;
        }
        final Activity activity = currentActivity;
        if (activity == null) {
            result.success(null);
            return;
        }
        final Uri uri = Uri.parse(uriStr);
        activity.runOnUiThread(() -> showVideoPlayer(activity, uri));
        result.success(null);
    }

    /** 全屏 VideoView 播放录制视频，右上角 ✕ 关闭。 */
    private void showVideoPlayer(Activity activity, Uri uri) {
        Dialog dialog = new Dialog(activity, android.R.style.Theme_Black_NoTitleBar_Fullscreen);
        dialog.setCancelable(true);

        FrameLayout frame = new FrameLayout(activity);
        frame.setBackgroundColor(Color.BLACK);

        VideoView videoView = new VideoView(activity);
        frame.addView(videoView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        ProgressBar progressBar = new ProgressBar(activity);
        frame.addView(progressBar, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER));

        TextView close = new TextView(activity);
        close.setText("✕");
        close.setTextSize(26);
        close.setTextColor(Color.WHITE);
        close.setGravity(Gravity.CENTER);
        FrameLayout.LayoutParams closeLp =
                new FrameLayout.LayoutParams(72, 72, Gravity.TOP | Gravity.END);
        closeLp.topMargin = 48;
        closeLp.rightMargin = 20;
        close.setOnClickListener(v -> dialog.dismiss());
        frame.addView(close, closeLp);

        MediaController controller = new MediaController(activity);
        videoView.setMediaController(controller);
        videoView.setOnPreparedListener(mp -> {
            progressBar.setVisibility(android.view.View.GONE);
            videoView.start();
        });
        videoView.setOnErrorListener((mp, what, extra) -> {
            progressBar.setVisibility(android.view.View.GONE);
            dialog.dismiss();
            return true;
        });
        videoView.setOnCompletionListener(mp -> dialog.dismiss());
        dialog.setOnDismissListener(d -> {
            try {
                videoView.stopPlayback();
            } catch (Exception ignored) {
            }
        });

        dialog.setContentView(frame);
        dialog.show();
        videoView.setVideoURI(uri);
    }

    /** 把某个媒体条目复制到系统相册（图库）。Q+ 走 MediaStore 插入，<=28 复制到公共 Pictures/Movies 目录并触发媒体扫描。 */
    private void saveMediaToAlbum(Map<String, Object> args, MethodChannel.Result result) {
        String uriStr = MapUtils.get(args, "uri", null);
        if (uriStr == null || uriStr.isEmpty()) {
            result.success(false);
            return;
        }
        // Dart 端已解析出视频/图片类型（content:// 路径不带后缀，原生无法自行判断）
        final boolean isVideo = MapUtils.get(args, "isVideo", false);
        final Uri uri = Uri.parse(uriStr);
        new Thread(() -> {
            try {
                boolean ok = copyToAlbum(uri, isVideo);
                android.util.Log.d("SIPSDK", "saveMediaToAlbum " + uri + " => " + ok);
                new Handler(Looper.getMainLooper()).post(() -> result.success(ok));
            } catch (Exception e) {
                android.util.Log.e("SIPSDK", "saveMediaToAlbum error " + uri, e);
                new Handler(Looper.getMainLooper()).post(() -> result.success(false));
            }
        }).start();
    }

    /** 按 uri 批量删除媒体文件（content:// 走 resolver，绝对路径直接删文件）。 */
    private void deleteMediaFiles(Map<String, Object> args, MethodChannel.Result result) {
        List<String> uris = MapUtils.get(args, "uris", null);
        if (uris == null) {
            result.success(false);
            return;
        }
        new Thread(() -> {
            boolean ok = true;
            for (String u : uris) {
                try {
                    if (u.startsWith("content://")) {
                        context.getContentResolver().delete(Uri.parse(u), null, null);
                    } else {
                        File f = new File(Uri.parse(u).getPath());
                        if (f.exists()) ok &= f.delete();
                    }
                } catch (Exception e) {
                    ok = false;
                }
            }
            final boolean res = ok;
            new Handler(Looper.getMainLooper()).post(() -> result.success(res));
        }).start();
    }

    /** 复制媒体字节到系统相册：Q+ 写 MediaStore（DCIM/Camera，保证相册必现），<=28 写公共 DCIM 目录并扫描。 */
    private boolean copyToAlbum(Uri source, boolean video) {
        String ext = video ? ".mp4" : ".jpg";
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Files 集合只允许 Download/Documents 目录，图片/视频落图库
                // 必须用 Images/Video 集合。
                // ColorOS（OPPO）对 Pictures/<应用名> 这类第三方目录的图片不放进
                // 「照片」主页面，只进「图集」。为保证相册必现，直接保存到相机胶卷
                // DCIM/Camera —— 这是任何相册都会显示的位置。
                // 标准做法：IS_PENDING=1 写入 → 写完置 0 发布。部分国产 ROM（OPPO）跳过
                // IS_PENDING 会生成 0 字节文件导致相册不显示，所以必须走完整的 pending 流程。
                String mime = video ? "video/mp4" : "image/jpeg";
                Uri collection = video
                        ? MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                        : MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
                long now = System.currentTimeMillis();
                ContentValues values = new ContentValues();
                values.put(MediaStore.MediaColumns.DISPLAY_NAME, "Doorbell_" + now + ext);
                values.put(MediaStore.MediaColumns.MIME_TYPE, mime);
                values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DCIM + "/Camera");
                values.put(MediaStore.MediaColumns.DATE_ADDED, now / 1000);
                values.put(MediaStore.MediaColumns.DATE_MODIFIED, now / 1000);
                values.put(MediaStore.MediaColumns.DATE_TAKEN, now);
                values.put(MediaStore.MediaColumns.IS_PENDING, 1);
                Uri insertUri = context.getContentResolver().insert(collection, values);
                if (insertUri == null) {
                    android.util.Log.e("SIPSDK", "saveToAlbum: insert returned null");
                    return false;
                }
                try (InputStream in = openMediaInput(source);
                     OutputStream os = context.getContentResolver().openOutputStream(insertUri)) {
                    if (in == null || os == null) return false;
                    byte[] buf = new byte[64 * 1024];
                    int read;
                    while ((read = in.read(buf)) != -1) {
                        os.write(buf, 0, read);
                    }
                }
                // 发布：IS_PENDING 置 0 并通知系统，相册此刻才索引完整文件
                ContentValues publish = new ContentValues();
                publish.put(MediaStore.MediaColumns.IS_PENDING, 0);
                context.getContentResolver().update(insertUri, publish, null, null);
                try {
                    context.getContentResolver().notifyChange(insertUri, null);
                } catch (Exception e) {
                    // 忽略
                }
                // 校验落盘文件：0 字节说明拷贝失败，直接返回 false 让前端提示失败
                String dataPath = getMediaDataPath(insertUri);
                if (dataPath != null) {
                    File f = new File(dataPath);
                    long size = f.exists() ? f.length() : -1;
                    android.util.Log.d("SIPSDK", "saveToAlbum file exists=" + f.exists()
                            + " size=" + size + " mime=" + mime);
                    if (!f.exists() || size <= 0) return false;
                    // 部分设备（OPPO 相册）仅靠 pending 发布仍不刷新，再补 scanFile + 广播
                    MediaScannerConnection.scanFile(context,
                            new String[]{dataPath}, new String[]{mime}, (path, uri) ->
                                    android.util.Log.d("SIPSDK", "saveToAlbum scanned " + path));
                    try {
                        Intent scanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
                        scanIntent.setData(Uri.fromFile(f));
                        context.sendBroadcast(scanIntent);
                    } catch (Exception e) {
                        android.util.Log.w("SIPSDK", "saveToAlbum broadcast scan failed", e);
                    }
                }
                android.util.Log.d("SIPSDK", "saveToAlbum ok => " + insertUri
                        + (dataPath != null ? " path=" + dataPath : " (no path)"));
                return true;
            } else {
                File publicDir = new File(Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_DCIM), "Camera");
                if (!publicDir.exists() && !publicDir.mkdirs()) return false;
                File dest = new File(publicDir, "Doorbell_" + System.currentTimeMillis() + ext);
                try (InputStream in = openMediaInput(source); OutputStream os = new FileOutputStream(dest)) {
                    if (in == null) return false;
                    byte[] buf = new byte[64 * 1024];
                    int read;
                    while ((read = in.read(buf)) != -1) {
                        os.write(buf, 0, read);
                    }
                }
                MediaScannerConnection.scanFile(context, new String[]{dest.getAbsolutePath()}, null, null);
                return true;
            }
        } catch (Exception e) {
            android.util.Log.e("SIPSDK", "copyToAlbum failed " + source, e);
            return false;
        }
    }

    /** 查询 content:// 条目对应的物理路径（用于触发媒体扫描）；查询不到返回 null。 */
    private String getMediaDataPath(Uri uri) {
        try (Cursor c = context.getContentResolver().query(
                uri, new String[]{MediaStore.MediaColumns.DATA}, null, null, null)) {
            if (c != null && c.moveToFirst()) {
                return c.getString(0);
            }
        } catch (Exception e) {
            // 忽略：部分设备不允许查询 _data，此时跳过手动扫描
        }
        return null;
    }

    /** 打开媒体输入流：content:// 或绝对路径。 */
    private InputStream openMediaInput(Uri uri) throws IOException {
        if ("content".equals(uri.getScheme())) {
            InputStream in = context.getContentResolver().openInputStream(uri);
            if (in == null) throw new IOException("cannot open stream for " + uri);
            return in;
        }
        File file = new File(uri.getPath());
        if (!file.exists()) throw new IOException("file not found: " + uri.getPath());
        return new FileInputStream(file);
    }

    private void call(Map<String, Object> args, MethodChannel.Result result) {
        int type = MapUtils.get(args, "type", SDKConstants.SDK_CALL_TYPE_SERVER);
        String username = MapUtils.get(args, "username", null);
        String remoteIp = MapUtils.get(args, "remoteIp", null);
        boolean transmitVideo = MapUtils.get(args, "transmitVideo", true);
        boolean transmitSound = MapUtils.get(args, "transmitSound", true);
        Map<String, String> headers = new HashMap<>();
        Map<String, Object> rawHeaders = MapUtils.getMap(args, "headers");
        if (rawHeaders != null) {
            for (Map.Entry<String, Object> entry : rawHeaders.entrySet()) {
                if (entry.getValue() instanceof String) {
                    headers.put(entry.getKey(), (String) entry.getValue());
                }
            }
        }
        SIPSDKCallParam param = new SIPSDKCallParam();
        param.callType = type;
        param.username = username;
        param.remoteIp = remoteIp;
        param.transmitVideo = transmitVideo;
        param.transmitSound = transmitSound;
        param.headers = headers;
        long uuid = SIPSDK.call(param);
        result.success(String.valueOf(uuid));
    }

    private void answer(Map<String, Object> args, MethodChannel.Result result) {
        int code = MapUtils.get(args, "code", 200);
        long callUuid = MapUtils.get(args, "callUuid", 0);
        SIPSDK.answer(code, callUuid);
        result.success(null);
    }

    private void sendDtmfInfo(Map<String, Object> args, MethodChannel.Result result) {
        long callUuid = MapUtils.get(args, "callUuid", 0);
        int dtmfInfoType = MapUtils.get(args, "dtmfInfoType",
                MapUtils.get(args, "type", SDK_DTMF_INFO_TYPE));
        String content = MapUtils.get(args, "content", null);
        String contentType = MapUtils.get(args, "contentType", null);
        SIPSDKDtmfInfoParam param = new SIPSDKDtmfInfoParam();
        param.callUuid = callUuid;
        param.dtmfInfoType = dtmfInfoType;
        param.content = content;
        param.contentType = contentType;
        SIPSDK.sendDtmfInfo(param);
        result.success(null);
    }

    private void sendMessage(Map<String, Object> args, MethodChannel.Result result) {
        int type = MapUtils.get(args, "type", SDKConstants.SDK_CALL_TYPE_SERVER);
        String username = MapUtils.get(args, "username", null);
        String remoteIp = MapUtils.get(args, "remoteIp", null);
        String content = MapUtils.get(args, "content", null);

        SIPSDKMessageParam param = new SIPSDKMessageParam();
        param.messageType = type;
        param.username = username;
        param.remoteIp = remoteIp;
        param.content = content;

        SIPSDK.sendMessage(param);
        result.success(null);
    }

    private void hangup(Map<String, Object> args, MethodChannel.Result result) {
        int code = MapUtils.get(args, "code", 487);
        long callUuid = MapUtils.get(args, "callUuid", 0);
        if (callUuid == 0) {
            SIPSDK.hangup(code);
        } else {
            SIPSDK.hangupWithUuid(code, callUuid);
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
        boolean restart = MapUtils.get(args, "restart", true);
        int restartDelay = MapUtils.get(args, "restartDelay", 500);
        SIPSDK.handleIpChange(restart, restartDelay);
        result.success(null);
    }

    /**
     * 开始录音
     */
    private void startRecording(Map<String, Object> args, MethodChannel.Result result) {
        int sampleRate = MapUtils.get(args, "sampleRate", AudioRecorder.instance().getSampleRate());
        AudioRecorder.instance().setSampleRate(sampleRate);
        AudioRecorder.instance().init();
        result.success(null);
    }

    /**
     * 停止录音
     */
    private void stopRecording(Map<String, Object> args, MethodChannel.Result result) {
        AudioRecorder.instance().destroy();
        result.success(null);
    }

    /**
     * 开始播放
     */
    private void startPlaying(Map<String, Object> args, MethodChannel.Result result) {
        int sampleRate = MapUtils.get(args, "sampleRate", AudioPlayer.instance().getSampleRate());
        AudioPlayer.instance().setSampleRate(sampleRate);
        AudioPlayer.instance().init();
        result.success(null);
    }

    /**
     * 停止播放
     */
    private void stopPlaying(Map<String, Object> args, MethodChannel.Result result) {
        AudioPlayer.instance().destroy();
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
        android.util.Log.d("SIPSDK", "isSpeaker => " + speaker);
        result.success(speaker);
    }

    private void setSpeaker(Map<String, Object> args, MethodChannel.Result result) {
        boolean speaker = MapUtils.get(args, "speaker", true);
        android.util.Log.d("SIPSDK", "setSpeaker <= " + speaker);
        AudioHandle.instance().speakerSwitch(speaker);
        result.success(null);
    }

    private void setImageRatio(Map<String, Object> args, MethodChannel.Result result) {
        boolean originalRatio = MapUtils.get(args, "originalRatio", false);
        VideoComponentView view = VideoComponentView.getCurrentInstance();
        if (view != null) {
            view.setImageRatio(originalRatio);
        }
        result.success(null);
    }

    private void clearVideo(Map<String, Object> args, MethodChannel.Result result) {
        VideoComponentView view = VideoComponentView.getCurrentInstance();
        if (view != null) {
            view.clearVideo();
        }
        result.success(null);
    }
}
