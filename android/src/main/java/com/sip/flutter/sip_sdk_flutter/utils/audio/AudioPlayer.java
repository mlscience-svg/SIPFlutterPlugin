package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.util.Log;

public class AudioPlayer {
    private final String TAG = AudioPlayer.class.getName();
    private AudioTrack audioTrack;

    public void init() {
        int sampleRate = 16000;  // 采样率
        int channelConfig = AudioFormat.CHANNEL_OUT_MONO;  // 单声道
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;  // 16位 PCM 数据
        // 创建 AudioTrack 对象
        audioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC,   // 使用音乐流
                sampleRate,                  // 采样率
                channelConfig,               // 声道配置（单声道）
                audioFormat,                 // 音频数据格式
                AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat),  // 缓冲区大小
                AudioTrack.MODE_STREAM);     // 流模式

        // 检查 AudioTrack 是否初始化成功
        if (audioTrack.getState() != AudioTrack.STATE_INITIALIZED) {
            Log.e("PcmPlayer", "AudioTrack initialization failed!");
            destroy();
            return;
        }
        // 启动播放
        audioTrack.play();
    }

    // 从 PCM 数据流播放音频（持续循环播放）
    public void play(byte[] data) {
        try {
            if (audioTrack == null) return;
            int offset = 0;
            while (offset < data.length) {
                // 每次读取 640 字节数据
                // 每次播放的 PCM 数据块大小
                int chunkSize = 640;
                int bytesToWrite = Math.min(chunkSize, data.length - offset);
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
            audioTrack.stop();
            audioTrack.release();
            audioTrack = null;
        }
    }
}
