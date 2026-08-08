package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.util.Log;

public class AudioPlayer {
    private final String TAG = AudioPlayer.class.getName();
    private int sampleRate = 16000;
    private int frameSize = 640;
    private AudioTrack audioTrack;

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
        destroy();
        int channelConfig = AudioFormat.CHANNEL_OUT_MONO;  // 单声道
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;  // 16位 PCM 数据
        int minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat);
        // 创建 AudioTrack 对象
        audioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC,   // 使用音乐流
                sampleRate,                  // 采样率
                channelConfig,               // 声道配置（单声道）
                audioFormat,                 // 音频数据格式
                minBufferSize,  // 缓冲区大小
                AudioTrack.MODE_STREAM);     // 流模式

        // 检查 AudioTrack 是否初始化成功
        if (audioTrack.getState() != AudioTrack.STATE_INITIALIZED) {
            Log.e("PcmPlayer", "AudioTrack initialization failed!");
            destroy();
            return;
        }
        Log.i(TAG, "AudioTrack init: sampleRate=" + sampleRate + ", frameSize=" + frameSize + ", minBufferSize=" + minBufferSize);
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
