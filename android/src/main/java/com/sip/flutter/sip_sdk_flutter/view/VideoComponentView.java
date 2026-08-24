package com.sip.flutter.sip_sdk_flutter.view;

import android.content.Context;
import android.graphics.Bitmap;
import android.opengl.GLSurfaceView;
import android.view.LayoutInflater;
import android.view.View;

import androidx.annotation.Nullable;


import com.sip.flutter.sip_sdk_flutter.R;
import com.sip.flutter.sip_sdk_flutter.codes.H264CodecImpl;
import com.sip.flutter.sip_sdk_flutter.view.cameragl.YUVRenderer;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.Map;

import io.flutter.plugin.platform.PlatformView;

public class VideoComponentView implements PlatformView, H264CodecImpl.DecodeCallback {
    final String TAG = VideoComponentView.class.getName();
    public interface SnapshotCallback {
        void onSnapshot(@Nullable byte[] bytes);
    }

    private static VideoComponentView currentInstance;
    private final View view;
    private final GLSurfaceView glSurfaceView;
    private final YUVRenderer yuvRenderer;

    VideoComponentView(final Context context, Map<String, Object> params) {
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        this.view = inflater.inflate(R.layout.view_video_component, null);

        glSurfaceView = this.view.findViewById(R.id.glSurfaceView);
        glSurfaceView.setEGLContextClientVersion(2);
        yuvRenderer = new YUVRenderer(glSurfaceView);
        glSurfaceView.setRenderer(yuvRenderer);

        // 先完成所有字段初始化再注册解码回调，避免解码线程在构造期间
        // 回调到尚未赋值的 yuvRenderer（全屏切换会反复重建本视图）。
        currentInstance = this;
        H264CodecImpl.addListener(this);
    }

    @Nullable
    public static VideoComponentView getCurrentInstance() {
        return currentInstance;
    }

    @Nullable
    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        H264CodecImpl.removeListener(this);
        if (currentInstance == this) {
            currentInstance = null;
        }
    }

    /**
     * 抓取对方视频当前帧，按解码出的原始分辨率生成 Bitmap。
     * 直接从 YUVRenderer 里拷贝 I420 原始帧再转 RGB，因此：
     * - 分辨率 = 对方发送的真实分辨率（不是视图大小）
     * - 没有 letterbox 黑边
     * 该方法不触碰 GL/UI 线程，可安全地在后台线程调用。
     */
    @Nullable
    public Bitmap captureBitmap() {
        YUVRenderer.FrameData frame = yuvRenderer.grabFrame();
        if (frame == null) {
            return null;
        }
        return yuv420ToBitmap(frame.data, frame.width, frame.height);
    }

    public void captureSnapshot(SnapshotCallback callback) {
        Bitmap bitmap = captureBitmap();
        if (bitmap == null) {
            callback.onSnapshot(null);
            return;
        }
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        callback.onSnapshot(stream.toByteArray());
    }

    /**
     * 切换远端视频显示比例。originalRatio=true → 1:1 按实际比例（留黑边）；
     * originalRatio=false → 铺满（拉伸铺满，变形）。默认 1:1。
     */
    public void setImageRatio(boolean originalRatio) {
        yuvRenderer.setFillScreen(!originalRatio);
    }

    /**
     * 清空视频表面（只留深灰清屏色），用于挂断/切换通道时清掉上一通道的残留画面。
     */
    public void clearVideo() {
        yuvRenderer.clearFrame();
    }

    /**
     * I420 (YUV420P) → ARGB_8888。转换系数与 YUVRenderer 的着色器一致
     * （全范围 BT.601）：R=Y+1.402V, G=Y-0.3441U-0.7141V, B=Y+1.772U。
     */
    private Bitmap yuv420ToBitmap(ByteBuffer yuv, int width, int height) {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        int[] pixels = new int[width * height];
        int ySize = width * height;
        int uvSize = ySize >> 2;
        int halfWidth = width >> 1;
        int idx = 0;
        for (int j = 0; j < height; j++) {
            int yRow = j * width;
            int uRowBase = ySize + (j >> 1) * halfWidth;
            for (int i = 0; i < width; i++) {
                int y = yuv.get(yRow + i) & 0xff;
                int uvIndex = uRowBase + (i >> 1);
                int u = (yuv.get(uvIndex) & 0xff) - 128;
                int v = (yuv.get(uvIndex + uvSize) & 0xff) - 128;
                int r = y + ((v * 1436) >> 10);
                int g = y - ((u * 352) >> 10) - ((v * 731) >> 10);
                int b = y + ((u * 1815) >> 10);
                r = r < 0 ? 0 : (r > 255 ? 255 : r);
                g = g < 0 ? 0 : (g > 255 ? 255 : g);
                b = b < 0 ? 0 : (b > 255 ? 255 : b);
                pixels[idx++] = 0xff000000 | (r << 16) | (g << 8) | b;
            }
        }
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height);
        return bitmap;
    }

    @Override
    public void onCallback(long callUuid, ByteBuffer outData, int outDataSize, int width, int height) {
        if (width == 0 || height == 0) {
            return;
        }
        YUVRenderer renderer = yuvRenderer;
        if (renderer == null) {
            return;
        }
        renderer.update(outData, outDataSize, width, height);
    }
}
