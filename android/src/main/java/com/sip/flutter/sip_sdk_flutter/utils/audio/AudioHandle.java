package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.content.Context;
import android.media.AudioManager;

import java.util.Arrays;

import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;
import com.sip.flutter.sip_sdk_flutter.utils.media.CallMediaRecorder;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.codes.PCMData;
import com.sip.sdk.i.SIPSDKMediaListener;

public class AudioHandle implements SIPSDKMediaListener.PCMReadListener,
        SIPSDKMediaListener.PCMWriteListener {
    private final String TAG = AudioHandle.class.getName();
    protected AudioManager audioManager;
    private volatile boolean micMuted = false;
    private volatile boolean speakerOn = true;
    // 录音和播放会各自申请一次通话音频模式，用计数配对，避免任一方先停止
    // 就提前恢复，导致另一路还在通话时音频被切回媒体通路。
    private int callAudioDepth = 0;
    // 进入通话前系统的原始模式/外放状态，全部退出时原样恢复。
    private int savedAudioMode = AudioManager.MODE_NORMAL;
    private boolean savedSpeakerOn = true;

    private static class Instance {
        private static final AudioHandle instance = new AudioHandle();
    }

    public static AudioHandle instance() {
        return Instance.instance;
    }

    public AudioHandle() {
        if (audioManager == null) {
            audioManager = (AudioManager) SipSdkFlutterPlugin.context.getSystemService(Context.AUDIO_SERVICE);
        }
        //默认speaker
        speakerSwitch(true);
        SIPSDK.addMediaListener(this);
    }

    /**
     * 通话期间必须使用 MODE_IN_COMMUNICATION，系统才会把
     * AudioRecorder 的 VOICE_COMMUNICATION 音源接入语音处理链
     * （硬件 AEC/NS/AGC），并让播放走语音通路。非通话时恢复
     * MODE_NORMAL，避免影响振铃、提示音和视频播放。
     */
    public synchronized void setCallAudioMode(boolean inCall) {
        if (audioManager == null) {
            return;
        }
        if (inCall) {
            if (callAudioDepth == 0) {
                // 只在首路进入时记录系统原始状态，后面的申请只计数。
                savedAudioMode = audioManager.getMode();
                savedSpeakerOn = audioManager.isSpeakerphoneOn();
                audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            }
            callAudioDepth++;
            audioManager.setSpeakerphoneOn(speakerOn);
        } else {
            if (callAudioDepth == 0) {
                return;
            }
            callAudioDepth--;
            if (callAudioDepth == 0) {
                // 全部退出后恢复通话前的模式和路由，否则媒体、提示音、
                // 视频仍会走语音通路或被强制外放。
                audioManager.setMode(savedAudioMode);
                audioManager.setSpeakerphoneOn(savedSpeakerOn);
            }
        }
    }

    // 打开/关闭扬声器（是否外放只影响路由，不改变通话音频模式）
    public void speakerSwitch(boolean b) {
        if (audioManager != null) {
            speakerOn = b;
            audioManager.setSpeakerphoneOn(b);
        }
    }

    // 关闭扬声器
    public boolean isSpeakerphoneOn() {
        if (audioManager != null) {
            return audioManager.isSpeakerphoneOn();
        }
        return false;
    }

    // 打开/关闭静音。不使用全局 setMicrophoneMute：它会同时影响系统录音，
    // 且各厂商实现不一致；这里在送 PCM 时把当前帧置零，行为可预期。
    public void microphoneMuteSwitch(boolean b) {
        micMuted = b;
    }

    // 是否静音
    public boolean isMicrophoneMute() {
        return micMuted;
    }

    @Override
    public PCMData pcmReadFrame() {
        byte[] bytes = AudioRecorder.instance().recording();
        if (bytes != null) {
            // 静音期间仍然把录音读空，避免 AudioRecord 内部缓冲积压；
            // 送给编码器的是全零的 20ms 帧，对端不会因此停收。
            if (micMuted) {
                Arrays.fill(bytes, (byte) 0);
            }
            PCMData pcmData = new PCMData();
            pcmData.data = bytes;
            pcmData.dataSize = bytes.length;
            return pcmData;
        }
        return null;
    }

    @Override
    public int pcmWriteFrame(byte[] data, int dataSize) {
        CallMediaRecorder.instance().onAudioFrame(data, dataSize, AudioPlayer.instance().getSampleRate());
        AudioPlayer.instance().play(data);
        return 0;
    }
}
