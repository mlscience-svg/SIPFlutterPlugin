package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.util.Log;

public class AudioPlayer {
    private final String TAG = AudioPlayer.class.getName();
    private int sampleRate = 16000;
    private int frameSize = 640;
    private AudioTrack audioTrack;
    // 是否已申请通话音频模式。init 可能被重复调用，保证与 destroy 一一配对。
    private boolean callAudioMode = false;

    private static class Instance {
        private static final AudioPlayer instance = new AudioPlayer();
    }

    public static AudioPlayer instance() {
        return AudioPlayer.Instance.instance;
    }

    public void setSampleRate(int sampleRate) {
        if (sampleRate > 0) {
            this.sampleRate = sampleRate;
            this.frameSize = Math.max(1, sampleRate / 50 * 2);
        }
    }

    public int getSampleRate() {
        return sampleRate;
    }

    public void init() {
        // 只释放旧通道，不退出通话模式：init 可能是重复调用。
        releaseTrack();
        if (!callAudioMode) {
            AudioHandle.instance().setCallAudioMode(true);
            callAudioMode = true;
        }
        int channelConfig = AudioFormat.CHANNEL_OUT_MONO;  // 单声道
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;  // 16位 PCM 数据
        int minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat);
        if (minBufferSize <= 0) {
            minBufferSize = frameSize * 8;
        }
        // 两倍最小缓冲：吸收回调线程的抖动，同时仍远小于人耳可感知的延迟。
        int bufferSize = Math.max(minBufferSize * 2, frameSize * 4);
        // 使用语音通话用途，系统才会把它当作 AEC 的远端参考信号；
        // 继续用 STREAM_MUSIC 时平台 AEC 拿不到正确的参考，回声消不干净。
        AudioAttributes attributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build();
        AudioFormat format = new AudioFormat.Builder()
                .setEncoding(audioFormat)
                .setSampleRate(sampleRate)
                .setChannelMask(channelConfig)
                .build();
        audioTrack = new AudioTrack.Builder()
                .setAudioAttributes(attributes)
                .setAudioFormat(format)
                .setBufferSizeInBytes(bufferSize)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build();

        // 检查 AudioTrack 是否初始化成功
        if (audioTrack.getState() != AudioTrack.STATE_INITIALIZED) {
            Log.e("PcmPlayer", "AudioTrack initialization failed!");
            destroy();
            return;
        }
        Log.i(TAG, "AudioTrack init: sampleRate=" + sampleRate + ", frameSize=" + frameSize + ", bufferSize=" + bufferSize);
        // 启动播放
        audioTrack.play();
    }

    // 从 PCM 数据流播放音频（持续循环播放）
    public void play(byte[] data) {
        try {
            if (audioTrack == null) return;
            int offset = 0;
            while (offset < data.length) {
                int bytesToWrite = Math.min(frameSize, data.length - offset);
                audioTrack.write(data, offset, bytesToWrite);
                offset += bytesToWrite;
            }
        } catch (Exception e) {
            Log.e(TAG, "Play data error", e);
        }
    }

    // 停止播放
    public void destroy() {
        releaseTrack();
        // 录音和播放都退出后，AudioHandle 会把系统模式和路由恢复成通话前的状态
        if (callAudioMode) {
            AudioHandle.instance().setCallAudioMode(false);
            callAudioMode = false;
        }
    }

    private void releaseTrack() {
        if (audioTrack != null) {
            try {
                audioTrack.stop();
            } catch (IllegalStateException ignored) {
            }
            audioTrack.release();
            audioTrack = null;
        }
    }
}
