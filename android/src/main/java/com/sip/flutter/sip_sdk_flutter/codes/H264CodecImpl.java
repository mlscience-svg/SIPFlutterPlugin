package com.sip.flutter.sip_sdk_flutter.codes;

import com.openh264.JNIOpenH264Manage;
import com.openh264.entity.DecoderConfig;
import com.openh264.entity.EncoderConfig;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraHandle;
import com.sip.flutter.sip_sdk_flutter.utils.camera.CameraInfo;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.codes.H264Codec;
import com.sip.sdk.codes.H264Data;
import com.sip.sdk.i.SIPSDKMediaListener;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

public class H264CodecImpl extends H264Codec {
    public static EncoderConfig econfig = new EncoderConfig();
    private static final int MAX_VIDEO_FPS = 25;
    private static final int MAX_VIDEO_WIDTH = 1920;
    private static final int MAX_VIDEO_HEIGHT = 1080;
    private static final int MIN_BLOCK_DATAS = 30;

    private long encoder = 0;
    private long decoder = 0;
    private CameraInfo cameraInfo = null;
    private byte[] encodeBuffer = null;

    private static final List<DecodeCallback> listeners = new ArrayList<>();

    static {
        SIPSDKMediaListener.InitCodecListener initCodecListener = new SIPSDKMediaListener.InitCodecListener() {
            @Override
            public H264Codec onInitCodec(long callUuid) {
                return new H264CodecImpl(callUuid);
            }
        };
        SIPSDK.addMediaListener(initCodecListener);
    }

    public interface DecodeCallback {
        void onCallback(long callUuid, byte[] outData, int[] outDataSize, int width, int height);
    }

    public static void addListener(DecodeCallback listener) {
        if (!listeners.contains(listener)) {
            listeners.add(listener);
        }
    }

    public static void removeListener(DecodeCallback listener) {
        listeners.remove(listener);
    }

    public H264CodecImpl(long callUuid) {
        super(callUuid);
        DecoderConfig decoderConfig = new DecoderConfig();
        decoder = JNIOpenH264Manage.initDecoder(decoderConfig);
        /* 配置最大视频支持参数 这里使用1080P */
        this.fps = MAX_VIDEO_FPS;
        this.width = MAX_VIDEO_WIDTH;
        this.height = MAX_VIDEO_HEIGHT;
        this.minBlockDatas = MIN_BLOCK_DATAS;
    }

    @Override
    public H264Data encode() {
        CameraInfo currentCameraInfo = CameraHandle.instance().getCurrentCameraInfo();
        if (currentCameraInfo != null) {
            if (cameraInfo == null ||
                    !Objects.equals(currentCameraInfo.cameraId, cameraInfo.cameraId) ||
                    !Objects.equals(currentCameraInfo.facing, cameraInfo.facing) ||
                    currentCameraInfo.previewSize.getWidth() != cameraInfo.previewSize.getWidth() ||
                    currentCameraInfo.previewSize.getHeight() != cameraInfo.previewSize.getHeight()) {
                rebuildEncoder(currentCameraInfo);
                return null;
            }
        }

        if (cameraInfo == null) {
            return null;
        }

        byte[] i420s = CameraHandle.instance().imageToI420();
        if (i420s == null) {
            return null;
        }
        int width, height;
        if (cameraInfo.rotation == 90 || cameraInfo.rotation == 270) {
            width = cameraInfo.previewSize.getHeight();
            height = cameraInfo.previewSize.getWidth();
        } else {
            width = cameraInfo.previewSize.getWidth();
            height = cameraInfo.previewSize.getHeight();
        }
        // 分配足够的编码缓冲区（YUV420 最大）
        int bufferSize = width * height * 3 / 2;
        if (encodeBuffer == null || encodeBuffer.length < bufferSize) {
            encodeBuffer = new byte[bufferSize];
        }

        int[] pktSize = new int[1];
        boolean[] isKeyframe = new boolean[1];
        boolean[] gotOutput = new boolean[1];

        JNIOpenH264Manage.encode(encoder, i420s, encodeBuffer, pktSize, isKeyframe, gotOutput);

        if (!gotOutput[0] || pktSize[0] <= 0) {
            return null;
        }

        H264Data h264Data = new H264Data();
        h264Data.data = Arrays.copyOf(encodeBuffer, pktSize[0]);
        h264Data.dataSize = pktSize[0];
        h264Data.isKeyframe = isKeyframe[0];
        return h264Data;
    }

    private void rebuildEncoder(CameraInfo info) {
        if (encoder != 0) {
            JNIOpenH264Manage.closeEncoder(encoder);
            encoder = 0;
        }
        cameraInfo = info;

        EncoderConfig config = new EncoderConfig();
        if (cameraInfo.rotation == 90 || cameraInfo.rotation == 270) {
            config.width = info.previewSize.getHeight();
            config.height = info.previewSize.getWidth();
        } else {
            config.width = info.previewSize.getWidth();
            config.height = info.previewSize.getHeight();
        }
        config.rcMode = econfig.rcMode;
        config.frameSkip = econfig.frameSkip;
        config.fps = econfig.fps;
        config.qp = econfig.qp;
        config.bps = econfig.bps;
        config.minBps = econfig.minBps;
        config.maxBps = econfig.maxBps;

        encoder = JNIOpenH264Manage.initEncoder(config);
    }

    @Override
    public int decode(long timestamp, int type, byte[] data, int dataSize) {
        if (decoder == 0 || data == null || dataSize <= 0) return -1;

        int maxSize = MAX_VIDEO_WIDTH * MAX_VIDEO_HEIGHT * 3 / 2;
        byte[] outData = new byte[maxSize];
        int[] outDataSize = new int[1];
        int[] width = new int[1];
        int[] height = new int[1];

        JNIOpenH264Manage.decode(decoder, data, dataSize, outData, outDataSize, width, height);

        if (outDataSize[0] <= 0 || width[0] <= 0 || height[0] <= 0) {
            return -1;
        }

        for (DecodeCallback callback : listeners) {
            callback.onCallback(callUuid, outData, outDataSize, width[0], height[0]);
        }

        return 0;
    }

    @Override
    public void deinit() {
        cameraInfo = null;
        encodeBuffer = null;

        if (encoder != 0) {
            JNIOpenH264Manage.closeEncoder(encoder);
            encoder = 0;
        }

        if (decoder != 0) {
            JNIOpenH264Manage.closeDecoder(decoder);
            decoder = 0;
        }
    }
}
