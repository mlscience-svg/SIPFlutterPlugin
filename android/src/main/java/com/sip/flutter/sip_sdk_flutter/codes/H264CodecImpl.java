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


import android.util.Log;

import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.StringJoiner;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.CopyOnWriteArrayList;

public class H264CodecImpl extends H264Codec {
    private static final String TAG = H264CodecImpl.class.getSimpleName();
    private static final long KEYFRAME_REQUEST_INTERVAL_MS = 1000L;
    private static final int DECODE_NO_OUTPUT = 1;
    private static final int DECODE_RET_NO_PARAM_SETS = -1016;
    private static final int NALU_TYPE_SLICE = 1;
    private static final int NALU_TYPE_IDR = 5;
    private static final int NALU_TYPE_SPS = 7;
    private static final int NALU_TYPE_PPS = 8;
    private static final int OPENH264_DS_ERROR_FREE = 0x00;
    private static final int OPENH264_DS_FRAME_PENDING = 0x01;
    private static final int OPENH264_DS_REF_LOST = 0x02;
    private static final int OPENH264_DS_BITSTREAM_ERROR = 0x04;
    private static final int OPENH264_DS_DEP_LAYER_LOST = 0x08;
    private static final int OPENH264_DS_NO_PARAM_SETS = 0x10;
    private static final int OPENH264_DS_DATA_ERROR_CONCEALED = 0x20;
    private static final int OPENH264_DS_REF_LIST_NULL_PTRS = 0x40;
    private static final int OPENH264_DS_INVALID_ARGUMENT = 0x1000;
    private static final int OPENH264_DS_INITIAL_OPT_EXPECTED = 0x2000;
    private static final int OPENH264_DS_OUT_OF_MEMORY = 0x4000;
    private static final int OPENH264_DS_DST_BUF_NEED_EXPAND = 0x8000;
    private static final int OPENH264_FATAL_STATE_MASK =
            OPENH264_DS_REF_LOST
                    | OPENH264_DS_BITSTREAM_ERROR
                    | OPENH264_DS_DEP_LAYER_LOST
                    | OPENH264_DS_OUT_OF_MEMORY
                    | OPENH264_DS_DST_BUF_NEED_EXPAND;
    private static final long KEYFRAME_RETRY_WHILE_WAITING_MS = 3000L;
    public static EncoderConfig econfig = createDefaultEncoderConfig();
    private static final int MAX_VIDEO_FPS = 30;
    private static final int MAX_VIDEO_WIDTH = 1920;
    private static final int MAX_VIDEO_HEIGHT = 1080;
    private static final long NO_PENDING_TIMESTAMP = Long.MIN_VALUE;
    private static final int INITIAL_ACCESS_UNIT_CAPACITY = 256 * 1024;

    private long encoder = 0;
    private long decoder = 0;
    private CameraInfo cameraInfo = null;
    private byte[] encodeBuffer = null;
    private final DecoderConfig decoderConfig = new DecoderConfig();

    private final ByteBuffer outData = ByteBuffer.allocateDirect(MAX_VIDEO_WIDTH * MAX_VIDEO_HEIGHT * 3 / 2);
    private final int[] outDataSize = new int[1];
    private final int[] widths = new int[1];
    private final int[] heights = new int[1];
    private final Object decoderLock = new Object();
    private int decodeFailCount = 0;
    private long lastKeyframeRequest = 0;
    private boolean waitingKeyframe = false;
    private boolean decoderNeedsReinit = false;
    private byte[] cachedSps = null;
    private byte[] cachedPps = null;
    private byte[] pendingAccessUnit = new byte[INITIAL_ACCESS_UNIT_CAPACITY];
    private int pendingAccessUnitSize = 0;
    private int pendingAccessUnitFirstType = -1;
    private long pendingAccessUnitTimestamp = NO_PENDING_TIMESTAMP;
    private boolean pendingAccessUnitHasVcl = false;

    private static final List<DecodeCallback> listeners = new CopyOnWriteArrayList<>();

    static {
        SIPSDKMediaListener.InitCodecListener initCodecListener = new SIPSDKMediaListener.InitCodecListener() {
            @Override
            public H264Codec onInitCodec(long callUuid) {
                return new H264CodecImpl(callUuid);
            }
        };
        SIPSDK.addMediaListener(initCodecListener);
    }

    private static EncoderConfig createDefaultEncoderConfig() {
        EncoderConfig config = new EncoderConfig();
        // 720P/30 至少需要更高目标码率，否则大运动场景下会频繁出现超大关键帧和花屏恢复慢。
        config.fps = 30;
        config.rcMode = EncoderConfig.RC_BITRATE_MODE;
        config.bps = 1200000;
        config.minBps = 800000;
        config.maxBps = 1500000;
        config.frameSkip = true;
        config.qp = 24;
        return config;
    }

    public interface DecodeCallback {
        void onCallback(long callUuid, ByteBuffer outData, int outDataSize, int width, int height);
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
        decoderConfig.videoBitstreamType = DecoderConfig.VIDEO_BITSTREAM_AVC;
        decoder = safeInitDecoder();
        /* 向 SIP SDK 声明支持到 1080P/30，并提高最小分块数量，避免 720P 大帧切块过粗。 */
        this.fps = MAX_VIDEO_FPS;
        this.width = MAX_VIDEO_WIDTH;
        this.height = MAX_VIDEO_HEIGHT;
        this.minBlockDatas = 160; //VGA: 35，720P: 60，1080P: 85
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
        if (isNativeHandleValid(encoder)) {
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

        long newEncoder = JNIOpenH264Manage.initEncoder(config);
        encoder = isNativeHandleValid(newEncoder) ? newEncoder : 0;
    }

    @Override
    public int decode(long timestamp, int type, byte[] data, int dataSize) {
        if (data == null || dataSize <= 0) return -1;
        synchronized (decoderLock) {
            if (!isNativeHandleValid(decoder)) {
                return -1;
            }
            if (pendingAccessUnitSize == 0) {
                resetPendingAccessUnit(timestamp, type);
                appendPendingAccessUnit(data, dataSize);
                return 0;
            }

            boolean incomingHasVcl = bufferContainsVclNal(data, dataSize);
            boolean shouldFlushPending =
                    pendingAccessUnitHasVcl
                            && (startsNewAccessUnit(data, dataSize)
                            || (incomingHasVcl && timestamp != pendingAccessUnitTimestamp));

            if (!shouldFlushPending) {
                appendPendingAccessUnit(data, dataSize);
                return 0;
            }

            int ret = decodeAccessUnit(
                    pendingAccessUnitFirstType,
                    pendingAccessUnit,
                    pendingAccessUnitSize
            );
            resetPendingAccessUnit(timestamp, type);
            appendPendingAccessUnit(data, dataSize);
            return ret;
        }
    }

    private int decodeAccessUnit(int type, byte[] data, int dataSize) {
        cacheParameterSets(data, dataSize);
        boolean containsIdr = type == NALU_TYPE_IDR || bufferContainsNalType(data, dataSize, NALU_TYPE_IDR);
        if (waitingKeyframe && !containsIdr) {
            return 0;
        }
        byte[] decodeData = data;
        int decodeDataSize = dataSize;
        if (waitingKeyframe && containsIdr) {
            byte[] combined = prependCachedParameterSets(data, dataSize);
            if (combined != null) {
                decodeData = combined;
                decodeDataSize = combined.length;
            }
        }
        int ret = JNIOpenH264Manage.decodeToDirectBuffer(
                decoder,
                decodeData,
                decodeDataSize,
                outData,
                outDataSize,
                widths,
                heights
        );
        if (ret == 0 || ret == DECODE_NO_OUTPUT) {
            decodeFailCount = 0;
            if (ret == 0) {
                if (decoderNeedsReinit) {
                    decoderNeedsReinit = false;
                }
                waitingKeyframe = false;
            }
            if (ret == DECODE_NO_OUTPUT) {
                return 0;
            }
        } else {
            int openH264State = decodeOpenH264StateValue(ret);
            if ((openH264State & OPENH264_DS_OUT_OF_MEMORY) != 0) {
                Log.e(TAG, "OpenH264 OUT_OF_MEMORY"
                        + ", type=" + type
                        + ", dataSize=" + dataSize
                        + ", ret=" + ret);
            }
            if ((openH264State & OPENH264_DS_DST_BUF_NEED_EXPAND) != 0) {
                Log.e(TAG, "OpenH264 DST_BUF_NEED_EXPAND"
                        + ", type=" + type
                        + ", dataSize=" + dataSize
                        + ", ret=" + ret);
            }
            decodeFailCount++;
            if (isFatalOpenH264State(openH264State)) {
                decodeFailCount = 0;
                waitingKeyframe = true;
                if (reinitDecoderIfNeeded(openH264State)) {
                    return shouldRequestKeyframeNow() ? 10000 : -1;
                }
                if (shouldRequestKeyframeNow()) {
                    Log.w(TAG, "request keyframe, reason=fatal decode state"
                            + ", ret=" + ret + " (" + decodeRetName(ret) + ")"
                            + ", type=" + type
                            + ", dataSize=" + dataSize);
                    return 10000;
                }
                return -1;
            }
            if (ret == DECODE_RET_NO_PARAM_SETS) {
                waitingKeyframe = true;
                if (decodeFailCount >= 10) {
                    decodeFailCount = 0;
                    if (shouldRequestKeyframeNow()) {
                        Log.w(TAG, "request keyframe, reason=no param sets"
                                + ", type=" + type
                                + ", dataSize=" + dataSize);
                        return 10000;
                    }
                }
                return -1;
            }
            if (decodeFailCount >= 10) {
                if (shouldRequestKeyframeNow()) {
                    decodeFailCount = 0;
                    waitingKeyframe = true;
                    Log.w(TAG, "request keyframe, reason=decode error burst"
                            + ", ret=" + ret + " (" + decodeRetName(ret) + ")"
                            + ", type=" + type
                            + ", dataSize=" + dataSize);
                    return 10000;
                }
            }
            return -1;
        }

        int decodedSize = outDataSize[0];
        int decodedWidth = widths[0];
        int decodedHeight = heights[0];
        if (decodedSize <= 0 || decodedWidth <= 0 || decodedHeight <= 0) {
            return -1;
        }
        if (decodedSize > outData.capacity()) {
            Log.e(TAG, "decoded frame too large for buffer, size=" + decodedSize + ", capacity=" + outData.capacity());
            return -1;
        }
        ByteBuffer frameBuffer = outData.duplicate();
        frameBuffer.position(0);
        frameBuffer.limit(decodedSize);
        ByteBuffer outputFrame = frameBuffer.slice();
        for (DecodeCallback callback : listeners) {
            callback.onCallback(callUuid, outputFrame.duplicate(), decodedSize, decodedWidth, decodedHeight);
        }
        return 0;
    }

    private void resetPendingAccessUnit(long timestamp, int type) {
        pendingAccessUnitTimestamp = timestamp;
        pendingAccessUnitFirstType = type;
        pendingAccessUnitSize = 0;
        pendingAccessUnitHasVcl = false;
    }

    private void appendPendingAccessUnit(byte[] data, int dataSize) {
        ensurePendingAccessUnitCapacity(pendingAccessUnitSize + dataSize);
        System.arraycopy(data, 0, pendingAccessUnit, pendingAccessUnitSize, dataSize);
        pendingAccessUnitSize += dataSize;
        pendingAccessUnitHasVcl = pendingAccessUnitHasVcl || bufferContainsVclNal(data, dataSize);
    }

    private void ensurePendingAccessUnitCapacity(int minCapacity) {
        if (pendingAccessUnit.length >= minCapacity) {
            return;
        }
        int newCapacity = pendingAccessUnit.length;
        while (newCapacity < minCapacity) {
            newCapacity <<= 1;
            if (newCapacity <= 0) {
                newCapacity = minCapacity;
                break;
            }
        }
        pendingAccessUnit = Arrays.copyOf(pendingAccessUnit, newCapacity);
    }

    @Override
    public void deinit() {
        synchronized (decoderLock) {
            cameraInfo = null;
            encodeBuffer = null;

            if (isNativeHandleValid(encoder)) {
                JNIOpenH264Manage.closeEncoder(encoder);
                encoder = 0;
            }

            if (isNativeHandleValid(decoder)) {
                JNIOpenH264Manage.closeDecoder(decoder);
                decoder = 0;
            }
            pendingAccessUnitSize = 0;
            pendingAccessUnitFirstType = -1;
            pendingAccessUnitTimestamp = NO_PENDING_TIMESTAMP;
            pendingAccessUnitHasVcl = false;
        }
    }

    private static String decodeRetName(int ret) {
        if (ret == DECODE_NO_OUTPUT) {
            return "NO_OUTPUT";
        }
        if (ret == DECODE_RET_NO_PARAM_SETS) {
            return "NO_PARAM_SETS";
        }
        if (ret <= -1000) {
            return decodeOpenH264State(-1000 - ret);
        }
        return "UNKNOWN";
    }

    private static int decodeOpenH264StateValue(int ret) {
        if (ret <= -1000) {
            return -1000 - ret;
        }
        if (ret == DECODE_RET_NO_PARAM_SETS) {
            return OPENH264_DS_NO_PARAM_SETS;
        }
        return 0;
    }

    private static boolean isFatalOpenH264State(int state) {
        return (state & OPENH264_FATAL_STATE_MASK) != 0;
    }

    private long safeInitDecoder() {
        long newDecoder = JNIOpenH264Manage.initDecoder(decoderConfig);
        return isNativeHandleValid(newDecoder) ? newDecoder : 0;
    }

    private boolean reinitDecoderIfNeeded(int openH264State) {
        if ((openH264State & (OPENH264_DS_REF_LOST | OPENH264_DS_NO_PARAM_SETS | OPENH264_DS_OUT_OF_MEMORY)) == 0) {
            return false;
        }
        if (isNativeHandleValid(decoder)) {
            JNIOpenH264Manage.closeDecoder(decoder);
            decoder = 0;
        }
        decoder = safeInitDecoder();
        decoderNeedsReinit = true;
        Log.w(TAG, "decoder reinitialized after fatal state, state=" + decodeOpenH264State(openH264State) + ", handle=" + decoder);
        return isNativeHandleValid(decoder);
    }

    private static boolean isNativeHandleValid(long handle) {
        return handle != 0 && handle != -1;
    }

    private void cacheParameterSets(byte[] data, int dataSize) {
        byte[] sps = extractNalUnit(data, dataSize, NALU_TYPE_SPS);
        if (sps != null) {
            cachedSps = sps;
        }
        byte[] pps = extractNalUnit(data, dataSize, NALU_TYPE_PPS);
        if (pps != null) {
            cachedPps = pps;
        }
    }

    private byte[] prependCachedParameterSets(byte[] data, int dataSize) {
        if (cachedSps == null || cachedPps == null) {
            return null;
        }
        if (bufferContainsNalType(data, dataSize, NALU_TYPE_SPS)
                || bufferContainsNalType(data, dataSize, NALU_TYPE_PPS)) {
            return null;
        }
        byte[] combined = new byte[cachedSps.length + cachedPps.length + dataSize];
        int offset = 0;
        System.arraycopy(cachedSps, 0, combined, offset, cachedSps.length);
        offset += cachedSps.length;
        System.arraycopy(cachedPps, 0, combined, offset, cachedPps.length);
        offset += cachedPps.length;
        System.arraycopy(data, 0, combined, offset, dataSize);
        return combined;
    }

    private static byte[] extractNalUnit(byte[] data, int size, int nalType) {
        int searchFrom = 0;
        while (true) {
            int startCodeOffset = findStartCodeOffset(data, size, searchFrom);
            if (startCodeOffset < 0) {
                return null;
            }
            int payloadOffset = findNalPayloadOffset(data, size, startCodeOffset);
            if (payloadOffset < 0 || payloadOffset >= size) {
                return null;
            }
            int nextStartCodeOffset = findStartCodeOffset(data, size, payloadOffset);
            if ((data[payloadOffset] & 0x1F) == nalType) {
                int endOffset = nextStartCodeOffset >= 0 ? nextStartCodeOffset : size;
                return Arrays.copyOfRange(data, startCodeOffset, endOffset);
            }
            searchFrom = payloadOffset;
        }
    }

    private static int findStartCodeOffset(byte[] data, int size, int fromIndex) {
        for (int i = Math.max(0, fromIndex); i < size - 3; i++) {
            if (data[i] == 0 && data[i + 1] == 0) {
                if (data[i + 2] == 1) {
                    return i;
                }
                if (i + 3 < size && data[i + 2] == 0 && data[i + 3] == 1) {
                    return i;
                }
            }
        }
        return -1;
    }

    private static boolean bufferContainsNalType(byte[] data, int size, int nalType) {
        for (int i = 0; i < size - 4; i++) {
            int offset = -1;
            if (data[i] == 0 && data[i + 1] == 0) {
                if (data[i + 2] == 1) {
                    offset = i + 3;
                } else if (i + 3 < size && data[i + 2] == 0 && data[i + 3] == 1) {
                    offset = i + 4;
                }
            }
            if (offset >= 0 && offset < size) {
                if ((data[offset] & 0x1F) == nalType) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean bufferContainsVclNal(byte[] data, int size) {
        return bufferContainsNalType(data, size, NALU_TYPE_SLICE)
                || bufferContainsNalType(data, size, NALU_TYPE_IDR);
    }

    private static boolean startsNewAccessUnit(byte[] data, int size) {
        int firstNalOffset = findNalPayloadOffset(data, size, 0);
        if (firstNalOffset < 0) {
            return false;
        }

        int nalType = data[firstNalOffset] & 0x1F;
        if (nalType == NALU_TYPE_SPS || nalType == NALU_TYPE_PPS || nalType == 6 || nalType == 9) {
            return true;
        }
        if (nalType == NALU_TYPE_SLICE || nalType == NALU_TYPE_IDR) {
            int firstMbInSlice = readFirstMbInSlice(data, size, firstNalOffset);
            return firstMbInSlice == 0;
        }

        int firstVclOffset = findFirstVclNalOffset(data, size);
        if (firstVclOffset < 0) {
            return false;
        }
        int firstVclType = data[firstVclOffset] & 0x1F;
        if (firstVclType == NALU_TYPE_SLICE || firstVclType == NALU_TYPE_IDR) {
            int firstMbInSlice = readFirstMbInSlice(data, size, firstVclOffset);
            return firstMbInSlice == 0;
        }
        return false;
    }

    private static int findFirstVclNalOffset(byte[] data, int size) {
        int searchFrom = 0;
        while (true) {
            int nalOffset = findNalPayloadOffset(data, size, searchFrom);
            if (nalOffset < 0) {
                return -1;
            }
            int nalType = data[nalOffset] & 0x1F;
            if (nalType == NALU_TYPE_SLICE || nalType == NALU_TYPE_IDR) {
                return nalOffset;
            }
            searchFrom = nalOffset + 1;
        }
    }

    private static int findNalPayloadOffset(byte[] data, int size, int fromIndex) {
        for (int i = Math.max(0, fromIndex); i < size - 3; i++) {
            if (data[i] == 0 && data[i + 1] == 0) {
                if (data[i + 2] == 1) {
                    return i + 3;
                }
                if (i + 3 < size && data[i + 2] == 0 && data[i + 3] == 1) {
                    return i + 4;
                }
            }
        }
        return -1;
    }

    private static int readFirstMbInSlice(byte[] data, int size, int nalOffset) {
        int rbspBitOffset = skipNalHeaderAndEmulationBytes(data, size, nalOffset);
        if (rbspBitOffset < 0) {
            return -1;
        }
        return readUnsignedExpGolomb(data, size, rbspBitOffset);
    }

    private static int skipNalHeaderAndEmulationBytes(byte[] data, int size, int nalOffset) {
        if (nalOffset < 0 || nalOffset >= size) {
            return -1;
        }
        return (nalOffset + 1) * 8;
    }

    private static int readUnsignedExpGolomb(byte[] data, int size, int bitOffset) {
        int leadingZeroBits = 0;
        while (true) {
            int bit = readRbspBit(data, size, bitOffset + leadingZeroBits);
            if (bit < 0) {
                return -1;
            }
            if (bit == 1) {
                break;
            }
            leadingZeroBits++;
            if (leadingZeroBits > 31) {
                return -1;
            }
        }

        int value = 1;
        for (int i = 0; i < leadingZeroBits; i++) {
            int bit = readRbspBit(data, size, bitOffset + leadingZeroBits + 1 + i);
            if (bit < 0) {
                return -1;
            }
            value = (value << 1) | bit;
        }
        return value - 1;
    }

    private static int readRbspBit(byte[] data, int size, int rbspBitIndex) {
        int nalByteIndex = rbspBitIndex / 8;
        int bitInByte = 7 - (rbspBitIndex % 8);
        int actualByteIndex = mapRbspByteIndexToNalIndex(data, size, nalByteIndex);
        if (actualByteIndex < 0 || actualByteIndex >= size) {
            return -1;
        }
        return (data[actualByteIndex] >> bitInByte) & 0x01;
    }

    private static int mapRbspByteIndexToNalIndex(byte[] data, int size, int rbspByteIndex) {
        int actualIndex = 0;
        int rbspIndex = 0;
        while (actualIndex < size) {
            if (actualIndex >= 2
                    && data[actualIndex] == 0x03
                    && data[actualIndex - 1] == 0x00
                    && data[actualIndex - 2] == 0x00) {
                actualIndex++;
                continue;
            }
            if (rbspIndex == rbspByteIndex) {
                return actualIndex;
            }
            rbspIndex++;
            actualIndex++;
        }
        return -1;
    }

    private boolean shouldRequestKeyframeNow() {
        long now = System.currentTimeMillis();
        if (waitingKeyframe && now - lastKeyframeRequest < KEYFRAME_RETRY_WHILE_WAITING_MS) {
            return false;
        }
        if (now - lastKeyframeRequest <= KEYFRAME_REQUEST_INTERVAL_MS) {
            return false;
        }
        lastKeyframeRequest = now;
        return true;
    }

    private static String decodeOpenH264State(int state) {
        if (state == OPENH264_DS_ERROR_FREE) {
            return "ERROR_FREE";
        }
        if (state == OPENH264_DS_FRAME_PENDING) {
            return "FRAME_PENDING";
        }

        StringJoiner joiner = new StringJoiner("|");
        appendOpenH264State(joiner, state, OPENH264_DS_REF_LOST, "REF_LOST");
        appendOpenH264State(joiner, state, OPENH264_DS_BITSTREAM_ERROR, "BITSTREAM_ERROR");
        appendOpenH264State(joiner, state, OPENH264_DS_DEP_LAYER_LOST, "DEP_LAYER_LOST");
        appendOpenH264State(joiner, state, OPENH264_DS_NO_PARAM_SETS, "NO_PARAM_SETS");
        appendOpenH264State(joiner, state, OPENH264_DS_DATA_ERROR_CONCEALED, "DATA_ERROR_CONCEALED");
        appendOpenH264State(joiner, state, OPENH264_DS_REF_LIST_NULL_PTRS, "REF_LIST_NULL_PTRS");
        appendOpenH264State(joiner, state, OPENH264_DS_INVALID_ARGUMENT, "INVALID_ARGUMENT");
        appendOpenH264State(joiner, state, OPENH264_DS_INITIAL_OPT_EXPECTED, "INITIAL_OPT_EXPECTED");
        appendOpenH264State(joiner, state, OPENH264_DS_OUT_OF_MEMORY, "OUT_OF_MEMORY");
        appendOpenH264State(joiner, state, OPENH264_DS_DST_BUF_NEED_EXPAND, "DST_BUF_NEED_EXPAND");

        String names = joiner.toString();
        if (names.isEmpty()) {
            return "OPENH264_STATE_" + state;
        }
        return names + "(0x" + Integer.toHexString(state) + ")";
    }

    private static void appendOpenH264State(StringJoiner joiner, int state, int mask, String name) {
        if ((state & mask) != 0) {
            joiner.add(name);
        }
    }

}
