package com.sip.flutter.sip_sdk_flutter.view;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class VideoComponentFactory extends PlatformViewFactory {
    private final Context context;

    public VideoComponentFactory(Context context) {
        super(StandardMessageCodec.INSTANCE);
        this.context = context.getApplicationContext();
    }

    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        Map<String, Object> params = (Map<String, Object>) args;
        // args是由Flutter传过来的自定义参数
        return new VideoComponentView(this.context, params);
    }
}
