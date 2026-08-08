package com.sip.flutter.sip_sdk_flutter.utils.audio;

import android.content.Context;
import android.media.AudioManager;

import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;
import com.sip.flutter.sip_sdk_flutter.utils.media.CallMediaRecorder;
import com.sip.sdk.SIPSDK;
import com.sip.sdk.codes.PCMData;
import com.sip.sdk.i.SIPSDKMediaListener;

public class AudioHandle implements SIPSDKMediaListener.PCMReadListener,
        SIPSDKMediaListener.PCMWriteListener {
    private final String TAG = AudioHandle.class.getName();
    protected AudioManager audioManager;

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

    // 打开扬声器
    public void speakerSwitch(boolean b) {
        if (audioManager != null) {
            if (b) {
                audioManager.setMode(AudioManager.MODE_NORMAL);
            } else {
                audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            }
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

    // 打开静音
    public void microphoneMuteSwitch(boolean b) {
        if (audioManager != null) {
            audioManager.setMicrophoneMute(b);
        }
    }

    // 关闭静音
    public boolean isMicrophoneMute() {
        if (audioManager != null) {
            return audioManager.isMicrophoneMute();
        }
        return false;
    }

    @Override
    public PCMData pcmReadFrame() {
        byte[] bytes = AudioRecorder.instance().recording();
        if (bytes != null) {
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
