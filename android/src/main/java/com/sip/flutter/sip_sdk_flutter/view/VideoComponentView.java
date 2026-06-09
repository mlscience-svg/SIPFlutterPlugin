package com.sip.flutter.sip_sdk_flutter.view;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.view.LayoutInflater;
import android.view.View;

import androidx.annotation.Nullable;


import com.sip.flutter.sip_sdk_flutter.R;
import com.sip.flutter.sip_sdk_flutter.codes.H264CodecImpl;
import com.sip.flutter.sip_sdk_flutter.view.cameragl.YUVRenderer;

import java.nio.ByteBuffer;
import java.util.Map;

import io.flutter.plugin.platform.PlatformView;

public class VideoComponentView implements PlatformView, H264CodecImpl.DecodeCallback {
    final String TAG = VideoComponentView.class.getName();
    private final View view;
    private final YUVRenderer yuvRenderer;

    VideoComponentView(final Context context, Map<String, Object> params) {
        H264CodecImpl.addListener(this);

        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        this.view = inflater.inflate(R.layout.view_video_component, null);

        GLSurfaceView glSurfaceView = this.view.findViewById(R.id.glSurfaceView);
        glSurfaceView.setEGLContextClientVersion(2);
        yuvRenderer = new YUVRenderer(glSurfaceView);
        glSurfaceView.setRenderer(yuvRenderer);
    }

    @Nullable
    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        H264CodecImpl.removeListener(this);
    }

    @Override
    public void onCallback(long callUuid, ByteBuffer outData, int outDataSize, int width, int height) {
        if (width == 0 || height == 0) {
            return;
        }
        yuvRenderer.update(outData, outDataSize, width, height);
    }
}
