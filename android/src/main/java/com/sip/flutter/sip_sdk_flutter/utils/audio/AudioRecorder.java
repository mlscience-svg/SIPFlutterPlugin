package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.Manifest;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;

import androidx.core.app.ActivityCompat;

import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;

public class AudioRecorder {
    private final int bufferSize = 640;
    private AudioRecord audioRecord = null;

    public void init() {
        if (ActivityCompat.checkSelfPermission(SipSdkFlutterPlugin.context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        // 采样率
        int sampleRate = 16000;
        // 单声道
        int channelConfig = AudioFormat.CHANNEL_IN_MONO;
        // 位深度
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;
        audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize);
        audioRecord.startRecording();
    }

    public byte[] recording() {
        if (audioRecord == null) {
            return null;
        }
        byte[] buffer = new byte[bufferSize];
        int bufferReadResult = audioRecord.read(buffer, 0, bufferSize);
        if (bufferReadResult > 0) {
            return buffer;
        }
        return null;
    }

    public void destroy() {
        if (audioRecord != null) {
            audioRecord.stop();
            audioRecord.release();
            audioRecord = null;
        }
    }
}
