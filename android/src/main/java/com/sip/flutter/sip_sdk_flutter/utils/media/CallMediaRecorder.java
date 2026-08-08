package com.sip.flutter.sip_sdk_flutter.utils.media;

import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.util.Log;

import androidx.annotation.Nullable;

import com.sip.flutter.sip_sdk_flutter.codes.H264CodecImpl;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicBoolean;

public class CallMediaRecorder implements H264CodecImpl.RawFrameCallback {
    private static final String TAG = CallMediaRecorder.class.getSimpleName();
    private static final String MIME_TYPE_AUDIO = "audio/mp4a-latm";
    private static final String MIME_TYPE_VIDEO = "video/avc";
    private static final int AUDIO_CHANNEL_COUNT = 1;
    private static final int AUDIO_BITRATE = 64000;
    private static final int AUDIO_TIMEOUT_US = 0;

    private final Object lock = new Object();
    private final List<PendingSample> pendingVideoSamples = new ArrayList<>();
    private final List<PendingSample> pendingAudioSamples = new ArrayList<>();
    private final MediaCodec.BufferInfo audioBufferInfo = new MediaCodec.BufferInfo();

    private MediaMuxer muxer;
    private MediaCodec audioEncoder;
    private String outputPath;
    private boolean recording;
    private boolean muxerStarted;
    private long recordingSessionId;
    private int videoTrackIndex = -1;
    private int audioTrackIndex = -1;
    private int audioSampleRate = 16000;
    private long audioPtsUs;
    private long recordingStartNs;
    private long activeCallUuid;
    private boolean seenVideoKeyframe;
    private int videoWidth;
    private int videoHeight;
    private byte[] cachedSps;
    private byte[] cachedPps;
    private static class Instance {
        private static final CallMediaRecorder INSTANCE = new CallMediaRecorder();
    }

    public static CallMediaRecorder instance() {
        return Instance.INSTANCE;
    }

    private final ConcurrentLinkedQueue<AudioChunk> audioQueue = new ConcurrentLinkedQueue<>();
    private final AtomicBoolean audioWorkerRunning = new AtomicBoolean(false);
    private Thread audioWorkerThread;

    @Nullable
    public String start(String path, int sampleRate) {
        synchronized (lock) {
            stopInternal();
            try {
                File file = new File(path);
                File parent = file.getParentFile();
                if (parent != null && !parent.exists() && !parent.mkdirs()) {
                    Log.e(TAG, "Failed to create parent directory: " + parent.getAbsolutePath());
                    return null;
                }
                if (file.exists() && !file.delete()) {
                    Log.w(TAG, "Failed to delete existing file: " + file.getAbsolutePath());
                }
                muxer = new MediaMuxer(file.getAbsolutePath(), MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
                outputPath = file.getAbsolutePath();
                audioSampleRate = sampleRate > 0 ? sampleRate : 16000;
                audioPtsUs = 0L;
                recordingStartNs = System.nanoTime();
                recordingSessionId++;
                activeCallUuid = 0L;
                seenVideoKeyframe = false;
                videoWidth = 0;
                videoHeight = 0;
                cachedSps = null;
                cachedPps = null;
                pendingVideoSamples.clear();
                pendingAudioSamples.clear();
                audioQueue.clear();
                videoTrackIndex = -1;
                audioTrackIndex = -1;
                muxerStarted = false;
                initAudioEncoder();
                recording = true;
                startAudioWorker();
                Log.w(TAG, "recording started, output=" + outputPath);
                return outputPath;
            } catch (IOException e) {
                Log.e(TAG, "Failed to start recorder", e);
                stopInternal();
                return null;
            }
        }
    }

    @Nullable
    public String stop() {
        synchronized (lock) {
            String path = outputPath;
            stopInternal();
            if (path == null) {
                return null;
            }
            File file = new File(path);
            if (!file.exists() || file.length() <= 0L) {
                if (file.exists() && !file.delete()) {
                    Log.w(TAG, "Failed to delete empty recording: " + path);
                }
                Log.w(TAG, "recording stopped but file is empty");
                return null;
            }
            Log.w(TAG, "recording stopped, fileSize=" + file.length());
            return path;
        }
    }

    public void onVideoFrame(long callUuid, byte[] data, int dataSize, int width, int height,
                             boolean keyframe, byte[] sps, byte[] pps) {
        synchronized (lock) {
            if (!recording || muxer == null || data == null || dataSize <= 0) {
                return;
            }
            if (activeCallUuid == 0L) {
                activeCallUuid = callUuid;
            } else if (activeCallUuid != callUuid) {
                return;
            }

            if (width > 0) {
                videoWidth = width;
            }
            if (height > 0) {
                videoHeight = height;
            }
            if (sps != null && sps.length > 0) {
                cachedSps = stripStartCode(sps);
            }
            if (pps != null && pps.length > 0) {
                cachedPps = stripStartCode(pps);
            }

            // 从 Annex-B 帧里抽出唯一一个延伸到帧尾的 VCL NAL，返回其裸字节（不带长度前缀）。
            // 这个厂商的 MPEG4Writer 会自己给每个 video sample 加 4 字节长度前缀；
            // 若我们传 AVCC（[len][NAL]），文件里就变成 [len][len][NAL] 双重前缀，
            // 解码器按 lengthSizeMinusOne=4 读第一个 len 作为 NAL 长度，读到 NAL 头是 0x00，
            // 直接 "missing picture in access unit"，只有声音没有画面。
            byte[] vclNal = extractVclNal(data, dataSize);
            if (vclNal.length == 0) {
                return;
            }
            ensureVideoTrack();
            if (!seenVideoKeyframe) {
                if (!keyframe) {
                    return;
                }
                seenVideoKeyframe = true;
            }

            long ptsUs = Math.max(0L, (System.nanoTime() - recordingStartNs) / 1000L);
            int flags = keyframe ? MediaCodec.BUFFER_FLAG_KEY_FRAME : 0;
            writeOrQueueSample(true, vclNal, ptsUs, flags);
        }
    }

    @Override
    public void onRawFrame(long callUuid, byte[] data, int dataSize, int width, int height,
                           boolean keyframe, byte[] sps, byte[] pps) {
        onVideoFrame(callUuid, data, dataSize, width, height, keyframe, sps, pps);
    }

    public void onAudioFrame(byte[] data, int dataSize, int sampleRate) {
        if (data == null || dataSize <= 0) {
            return;
        }
        synchronized (lock) {
            if (!recording || audioEncoder == null) {
                return;
            }
            if (sampleRate > 0 && sampleRate != audioSampleRate) {
                Log.w(TAG, "Ignore audio sample rate change during recording: " + sampleRate);
            }
        }
        byte[] frame = Arrays.copyOf(data, dataSize);
        if (audioQueue.size() > 120) {
            audioQueue.poll();
        }
        audioQueue.offer(new AudioChunk(recordingSessionId, frame));
    }

    private void startAudioWorker() {
        if (!audioWorkerRunning.compareAndSet(false, true)) {
            return;
        }
        audioWorkerThread = new Thread(() -> {
            while (audioWorkerRunning.get()) {
                AudioChunk chunk = audioQueue.poll();
                if (chunk == null) {
                    try {
                        Thread.sleep(5L);
                    } catch (InterruptedException ignored) {
                    }
                    continue;
                }
                synchronized (lock) {
                    if (!recording || recordingSessionId != chunk.sessionId || audioEncoder == null) {
                        continue;
                    }
                    feedAudioEncoder(chunk.data, chunk.data.length);
                    drainAudioEncoder(false);
                }
            }
        }, "CallMediaRecorder-Audio");
        audioWorkerThread.start();
    }

    private void stopAudioWorker() {
        audioWorkerRunning.set(false);
        if (audioWorkerThread != null) {
            audioWorkerThread.interrupt();
            audioWorkerThread = null;
        }
    }

    private void initAudioEncoder() throws IOException {
        MediaFormat format = MediaFormat.createAudioFormat(
                MIME_TYPE_AUDIO,
                audioSampleRate,
                AUDIO_CHANNEL_COUNT
        );
        format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC);
        format.setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BITRATE);
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16 * 1024);
        audioEncoder = MediaCodec.createEncoderByType(MIME_TYPE_AUDIO);
        audioEncoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        audioEncoder.start();
    }

    private void feedAudioEncoder(byte[] data, int dataSize) {
        int offset = 0;
        while (offset < dataSize && audioEncoder != null) {
            int inputIndex = audioEncoder.dequeueInputBuffer(AUDIO_TIMEOUT_US);
            if (inputIndex < 0) {
                break;
            }
            ByteBuffer inputBuffer = audioEncoder.getInputBuffer(inputIndex);
            if (inputBuffer == null) {
                audioEncoder.queueInputBuffer(inputIndex, 0, 0, audioPtsUs, 0);
                continue;
            }
            inputBuffer.clear();
            int bytesToWrite = Math.min(inputBuffer.remaining(), dataSize - offset);
            inputBuffer.put(data, offset, bytesToWrite);
            long ptsUs = audioPtsUs;
            int sampleCount = bytesToWrite / 2;
            audioPtsUs += sampleCount * 1_000_000L / audioSampleRate;
            audioEncoder.queueInputBuffer(inputIndex, 0, bytesToWrite, ptsUs, 0);
            offset += bytesToWrite;
        }
    }

    private void drainAudioEncoder(boolean endOfStream) {
        if (audioEncoder == null) {
            return;
        }
        if (endOfStream) {
            int inputIndex = audioEncoder.dequeueInputBuffer(AUDIO_TIMEOUT_US);
            if (inputIndex >= 0) {
                audioEncoder.queueInputBuffer(
                        inputIndex,
                        0,
                        0,
                        audioPtsUs,
                        MediaCodec.BUFFER_FLAG_END_OF_STREAM
                );
            }
        }

        while (true) {
            int outputIndex = audioEncoder.dequeueOutputBuffer(audioBufferInfo, AUDIO_TIMEOUT_US);
            if (outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                break;
            }
            if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                if (audioTrackIndex < 0 && muxer != null) {
                    audioTrackIndex = muxer.addTrack(audioEncoder.getOutputFormat());
                    maybeStartMuxer();
                }
                continue;
            }
            if (outputIndex < 0) {
                continue;
            }

            ByteBuffer outputBuffer = audioEncoder.getOutputBuffer(outputIndex);
            if (outputBuffer != null && audioBufferInfo.size > 0) {
                outputBuffer.position(audioBufferInfo.offset);
                outputBuffer.limit(audioBufferInfo.offset + audioBufferInfo.size);
                byte[] bytes = new byte[audioBufferInfo.size];
                outputBuffer.get(bytes);
                writeOrQueueSample(false, bytes, audioBufferInfo.presentationTimeUs, audioBufferInfo.flags);
            }
            audioEncoder.releaseOutputBuffer(outputIndex, false);

            if ((audioBufferInfo.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                break;
            }
        }
    }

    private void ensureVideoTrack() {
        if (videoTrackIndex >= 0 || muxer == null || videoWidth <= 0 || videoHeight <= 0
                || cachedSps == null || cachedPps == null) {
            return;
        }
        MediaFormat format = MediaFormat.createVideoFormat(MIME_TYPE_VIDEO, videoWidth, videoHeight);
        // 用带起始码（Annex-B）的 SPS/PPS 作为 csd-0/csd-1，与 MediaCodec 编码器的
        // 输出格式保持一致；MPEG4Writer 写 avcC box 时会自己去掉起始码。
        byte[] csd0 = prependStartCode(cachedSps);
        byte[] csd1 = prependStartCode(cachedPps);
        format.setByteBuffer("csd-0", ByteBuffer.wrap(csd0));
        format.setByteBuffer("csd-1", ByteBuffer.wrap(csd1));
        videoTrackIndex = muxer.addTrack(format);
        maybeStartMuxer();
    }

    private void maybeStartMuxer() {
        if (muxerStarted || muxer == null || videoTrackIndex < 0 || audioTrackIndex < 0) {
            return;
        }
        muxer.start();
        muxerStarted = true;
        flushPendingSamples();
    }

    private void flushPendingSamples() {
        for (PendingSample sample : pendingVideoSamples) {
            writeSampleData(videoTrackIndex, sample);
        }
        pendingVideoSamples.clear();
        for (PendingSample sample : pendingAudioSamples) {
            writeSampleData(audioTrackIndex, sample);
        }
        pendingAudioSamples.clear();
    }

    private void writeOrQueueSample(boolean video, byte[] data, long ptsUs, int flags) {
        if (data.length == 0) {
            return;
        }
        PendingSample sample = new PendingSample(data, ptsUs, flags);
        if (!muxerStarted) {
            if (video) {
                pendingVideoSamples.add(sample);
            } else {
                pendingAudioSamples.add(sample);
            }
            return;
        }
        int trackIndex = video ? videoTrackIndex : audioTrackIndex;
        writeSampleData(trackIndex, sample);
    }

    private void writeSampleData(int trackIndex, PendingSample sample) {
        if (muxer == null || trackIndex < 0) {
            return;
        }
        MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
        bufferInfo.offset = 0;
        bufferInfo.size = sample.data.length;
        bufferInfo.presentationTimeUs = sample.ptsUs;
        bufferInfo.flags = sample.flags;
        muxer.writeSampleData(trackIndex, ByteBuffer.wrap(sample.data), bufferInfo);
    }

    private void stopInternal() {
        boolean hadRecording = recording;
        recording = false;
        if (audioEncoder != null) {
            try {
                if (hadRecording) {
                    drainAudioEncoder(true);
                }
            } catch (Exception e) {
                Log.w(TAG, "Failed draining audio encoder", e);
            }
            try {
                audioEncoder.stop();
            } catch (Exception e) {
                Log.w(TAG, "Failed stopping audio encoder", e);
            }
            try {
                audioEncoder.release();
            } catch (Exception e) {
                Log.w(TAG, "Failed releasing audio encoder", e);
            }
            audioEncoder = null;
        }
        stopAudioWorker();
        if (muxer != null) {
            try {
                if (muxerStarted) {
                    muxer.stop();
                }
            } catch (Exception e) {
                Log.w(TAG, "Failed stopping muxer", e);
            }
            try {
                muxer.release();
            } catch (Exception e) {
                Log.w(TAG, "Failed releasing muxer", e);
            }
            muxer = null;
        }
        muxerStarted = false;
        videoTrackIndex = -1;
        audioTrackIndex = -1;
        pendingVideoSamples.clear();
        pendingAudioSamples.clear();
        cachedSps = null;
        cachedPps = null;
        activeCallUuid = 0L;
        seenVideoKeyframe = false;
        videoWidth = 0;
        videoHeight = 0;
        audioPtsUs = 0L;
        outputPath = null;
        recordingSessionId++;
    }

    /**
     * 从一帧 Annex-B 码流里抽出”唯一一个且延伸到帧尾”的 VCL NAL，返回其裸字节
     * （不带起始码、不带长度前缀）。
     *
     * 正常的一帧（单 slice 流）应该恰好包含 1 个 VCL NAL（IDR/slice），且它一直延伸到帧尾。
     * 远端码流若丢失了防竞争字节（00 00 03），slice 内部会出现伪 start code（00 00 01），
     * 朴素扫描会把 slice 切碎；OPPO 等厂商的 MPEG4Writer 遇到坏长度前缀会 abort
     * （FORTIFY write count=-1）。所以任何可疑帧整个丢弃。
     */
    private static byte[] extractVclNal(byte[] data, int size) {
        int vclOffset = -1;
        int vclLength = 0;
        int vclCount = 0;
        boolean vclExtendsToEnd = false;
        int offset = 0;
        while (offset < size) {
            int start = findStartCodeOffset(data, size, offset);
            if (start < 0) {
                break;
            }
            int nalOffset = findNalPayloadOffset(data, size, start);
            if (nalOffset < 0 || nalOffset >= size) {
                break;
            }
            int nalType = data[nalOffset] & 0x1F;
            int nextStart = findStartCodeOffset(data, size, nalOffset);
            int nalEnd = nextStart >= 0 ? nextStart : size;
            if (nalType >= 1 && nalType <= 5) {
                int nalLength = nalEnd - nalOffset;
                if (nalLength > 0) {
                    if (vclCount == 0) {
                        vclOffset = nalOffset;
                        vclLength = nalLength;
                        vclExtendsToEnd = (nextStart < 0);
                    }
                    vclCount++;
                }
            }
            offset = nalEnd;
        }
        if (vclCount != 1 || !vclExtendsToEnd || vclOffset < 0 || vclLength <= 0) {
            return new byte[0];
        }
        return Arrays.copyOfRange(data, vclOffset, vclOffset + vclLength);
    }

    private static byte[] stripStartCode(byte[] data) {
        int payloadOffset = findNalPayloadOffset(data, data.length, 0);
        if (payloadOffset <= 0 || payloadOffset >= data.length) {
            return Arrays.copyOf(data, data.length);
        }
        return Arrays.copyOfRange(data, payloadOffset, data.length);
    }

    /** 给裸 NAL 前面补上 4 字节起始码 00 00 00 01（已是起始码开头则原样返回）。 */
    private static byte[] prependStartCode(byte[] nal) {
        if (nal.length >= 4 && nal[0] == 0 && nal[1] == 0 && nal[2] == 0 && nal[3] == 1) {
            return nal;
        }
        byte[] out = new byte[nal.length + 4];
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        System.arraycopy(nal, 0, out, 4, nal.length);
        return out;
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

    private static int findNalPayloadOffset(byte[] data, int size, int startCodeOffset) {
        if (startCodeOffset + 3 >= size) {
            return -1;
        }
        if (data[startCodeOffset] == 0 && data[startCodeOffset + 1] == 0) {
            if (data[startCodeOffset + 2] == 1) {
                return startCodeOffset + 3;
            }
            if (startCodeOffset + 3 < size && data[startCodeOffset + 2] == 0
                    && data[startCodeOffset + 3] == 1) {
                return startCodeOffset + 4;
            }
        }
        return -1;
    }

    private static class PendingSample {
        final byte[] data;
        final long ptsUs;
        final int flags;

        PendingSample(byte[] data, long ptsUs, int flags) {
            this.data = data;
            this.ptsUs = ptsUs;
            this.flags = flags;
        }
    }

    private static class AudioChunk {
        final long sessionId;
        final byte[] data;

        AudioChunk(long sessionId, byte[] data) {
            this.sessionId = sessionId;
            this.data = data;
        }
    }
}
