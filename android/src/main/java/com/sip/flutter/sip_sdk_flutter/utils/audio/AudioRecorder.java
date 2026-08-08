package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.Manifest;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.util.Log;

import androidx.core.app.ActivityCompat;

import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;

public class AudioRecorder {
    private static final String TAG = AudioRecorder.class.getSimpleName();
    private int sampleRate = 16000;
    private int frameSize = 640;
    private int bufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT);
    private AudioRecord audioRecord = null;

    private static class Instance {
        private static final AudioRecorder instance = new AudioRecorder();
    }

    public static AudioRecorder instance() {
        return AudioRecorder.Instance.instance;
    }

    public void setSampleRate(int sampleRate) {
        if (sampleRate <= 0) return;
        this.sampleRate = sampleRate;
        this.frameSize = Math.max(1, sampleRate / 50 * 2);
        this.bufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT);
        if (this.bufferSize < frameSize) {
            this.bufferSize = frameSize;
        }
    }

    public int getSampleRate() {
        return sampleRate;
    }

    public void init() {
        if (ActivityCompat.checkSelfPermission(SipSdkFlutterPlugin.context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        destroy();
        // 单声道
        int channelConfig = AudioFormat.CHANNEL_IN_MONO;
        // 位深度
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;
        audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize);
        Log.i(TAG, "AudioRecord init: sampleRate=" + sampleRate + ", frameSize=" + frameSize + ", bufferSize=" + bufferSize);
        audioRecord.startRecording();
    }

    public byte[] recording() {
        if (audioRecord == null) {
            return null;
        }
        byte[] buffer = new byte[frameSize];
        int bufferReadResult = audioRecord.read(buffer, 0, frameSize);
        if (bufferReadResult > 0) {
            if (bufferReadResult == buffer.length) {
                return buffer;
            }
            byte[] result = new byte[bufferReadResult];
            System.arraycopy(buffer, 0, result, 0, bufferReadResult);
            return result;
        }
        return null;
    }

    public void destroy() {
        if (audioRecord != null) {
            try {
                audioRecord.stop();
            } catch (IllegalStateException ignored) {
            }
            audioRecord.release();
            audioRecord = null;
        }
    }
}
