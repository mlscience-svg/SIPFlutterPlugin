package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.Manifest;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.media.audiofx.AcousticEchoCanceler;
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
    private AcousticEchoCanceler aec = null;
    // 是否已申请通话音频模式。init 可能被重复调用，保证与 destroy 一一配对。
    private boolean callAudioMode = false;

    /** 系统是否提供 AEC 效果。有系统 AEC 时 SDK 侧的 AECM 必须关闭，避免重复处理。 */
    public static boolean isPlatformAecAvailable() {
        return AcousticEchoCanceler.isAvailable();
    }

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
        release();
        // 通话期间切到通话音频模式，VOICE_COMMUNICATION 音源才会走语音处理链
        if (!callAudioMode) {
            AudioHandle.instance().setCallAudioMode(true);
            callAudioMode = true;
        }
        // 单声道
        int channelConfig = AudioFormat.CHANNEL_IN_MONO;
        // 位深度
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;
        // VOICE_COMMUNICATION 让系统 AEC/NS/AGC（含厂商硬件实现）参与采集；
        // 这些处理会跟随设备自身延迟自适应，不依赖 SDK 里写死的声卡延时。
        audioRecord = new AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, sampleRate, channelConfig, audioFormat, bufferSize);
        Log.i(TAG, "AudioRecord init: sampleRate=" + sampleRate + ", frameSize=" + frameSize + ", bufferSize=" + bufferSize);
        if (audioRecord.getState() != AudioRecord.STATE_INITIALIZED) {
            Log.e(TAG, "AudioRecord initialization failed, state=" + audioRecord.getState());
            // 走统一的销毁路径，把刚申请的通话音频模式还回去。
            destroy();
            return;
        }
        audioRecord.startRecording();
        attachPlatformAec();
    }

    private void attachPlatformAec() {
        if (!AcousticEchoCanceler.isAvailable()) {
            Log.w(TAG, "platform AEC not available, SDK AEC will be used");
            return;
        }
        try {
            aec = AcousticEchoCanceler.create(audioRecord.getAudioSessionId());
            if (aec != null) {
                aec.setEnabled(true);
                Log.i(TAG, "platform AEC attached, session=" + audioRecord.getAudioSessionId());
            } else {
                Log.w(TAG, "platform AEC create returned null");
            }
        } catch (Exception e) {
            aec = null;
            Log.e(TAG, "platform AEC attach failed", e);
        }
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
        release();
        // 通话结束恢复普通音频模式，避免影响振铃、提示音等系统声音
        if (callAudioMode) {
            AudioHandle.instance().setCallAudioMode(false);
            callAudioMode = false;
        }
    }

    private void release() {
        if (aec != null) {
            try {
                aec.setEnabled(false);
            } catch (Exception ignored) {
            }
            aec.release();
            aec = null;
        }
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
