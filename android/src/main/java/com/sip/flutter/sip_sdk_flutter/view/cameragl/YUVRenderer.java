package com.sip.flutter.sip_sdk_flutter.view.cameragl;

import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.GLSurfaceView.Renderer;
import android.util.Log;

import androidx.annotation.Nullable;

import java.nio.Buffer;
import java.nio.ByteBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class YUVRenderer implements Renderer {
    private static final String TAG = YUVRenderer.class.getSimpleName();
    private final GLSurfaceView mTargetSurface;
    private final GLProgram prog = new GLProgram();
    private final Object frameLock = new Object();
    private int mScreenWidth, mScreenHeight;
    private int mVideoWidth, mVideoHeight;
    private ByteBuffer pendingFrame;
    private ByteBuffer renderFrame;
    private int renderWidth;
    private int renderHeight;
    private int pendingWidth;
    private int pendingHeight;
    private int pendingFrameSize;
    private boolean hasPendingFrame;
    private boolean hasUploadedFrame;
    private int droppedFrameCount;
    /** true=铺满（拉伸铺满，变形），false=1:1 按实际比例居中留黑边。默认1:1。 */
    private volatile boolean fillScreen = false;

    /** 当前正在显示的原始视频帧（I420 格式）及真实分辨率。 */
    public static class FrameData {
        public final ByteBuffer data; // I420: Y 平面 + U 平面 + V 平面，已 flip
        public final int width;
        public final int height;

        FrameData(ByteBuffer data, int width, int height) {
            this.data = data;
            this.width = width;
            this.height = height;
        }
    }

    /**
     * 抓取当前已经上屏的那一帧的副本（I420 + 原始分辨率）。
     * 与 GL 线程通过 frameLock 同步，可安全地从后台线程调用。
     * 尚未解码出任何帧时返回 null。
     */
    @Nullable
    public FrameData grabFrame() {
        synchronized (frameLock) {
            if (renderFrame == null) {
                return null;
            }
            ByteBuffer copy = ByteBuffer.allocateDirect(renderFrame.capacity());
            ByteBuffer src = renderFrame.duplicate();
            src.position(0);
            src.limit(renderFrame.limit());
            copy.put(src);
            copy.flip();
            return new FrameData(copy, renderWidth, renderHeight);
        }
    }

    public YUVRenderer(GLSurfaceView surface) {
        mTargetSurface = surface;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        prog.reset();
        prog.buildProgram();
        prog.createBuffers(GLProgram.squareVertices);
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        mScreenWidth = width;
        mScreenHeight = height;
        GLES20.glViewport(0, 0, width, height);
        updateVertices();
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        ByteBuffer frame = null;
        int frameWidth = 0;
        int frameHeight = 0;
        int frameSize = 0;
        synchronized (frameLock) {
            if (hasPendingFrame) {
                ByteBuffer temp = renderFrame;
                renderFrame = pendingFrame;
                pendingFrame = temp;
                frame = renderFrame.duplicate();
                frameWidth = pendingWidth;
                frameHeight = pendingHeight;
                frameSize = pendingFrameSize;
                renderWidth = pendingWidth;
                renderHeight = pendingHeight;
                hasPendingFrame = false;
            }
        }

        if (frame != null) {
            resize(frameWidth, frameHeight);
            int ySize = frameWidth * frameHeight;
            int uvSize = ySize / 4;
            ByteBuffer yData = slicePlane(frame, 0, ySize);
            ByteBuffer uData = slicePlane(frame, ySize, uvSize);
            ByteBuffer vData = slicePlane(frame, ySize + uvSize, uvSize);
            prog.buildTextures(new Buffer[]{yData, uData, vData}, frameWidth, frameHeight);
            hasUploadedFrame = true;
        }

        // 清屏色用深灰（0xFF2E2E2E）而非纯黑，让视频区域（含 1:1 黑边）与上下纯黑功能条能区分开
        GLES20.glClearColor(0.18f, 0.18f, 0.18f, 1.0f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        if (hasUploadedFrame) {
            prog.drawFrame();
        }
    }

    private void resize(int width, int height) {
        if (width != mVideoWidth || height != mVideoHeight) {
            this.mVideoWidth = width;
            this.mVideoHeight = height;
            updateVertices();
        }
    }

    /**
     * 切换视频显示比例。
     * fill=true 铺满：拉伸铺满整个视口（会变形）；
     * fill=false 1:1：按实际比例居中显示，上下/左右留黑边。
     * 默认 1:1。顶点在渲染线程重建，避免跨线程调用 GL。
     */
    public void setFillScreen(boolean fill) {
        if (fillScreen == fill) {
            return;
        }
        fillScreen = fill;
        mTargetSurface.queueEvent(this::updateVertices);
        mTargetSurface.requestRender();
    }

    /**
     * 清除已上屏的最后一帧。之后 onDrawFrame 只画清屏色（深灰），不再绘制旧画面；
     * 用于挂断/切换通道时清掉上一通道的残留帧。下一帧解码数据到达后自动恢复显示。
     * 通过 queueEvent 在 GL 线程执行，与 onDrawFrame 顺序一致，线程安全。
     */
    public void clearFrame() {
        mTargetSurface.queueEvent(() -> {
            synchronized (frameLock) {
                hasUploadedFrame = false;
                hasPendingFrame = false;
                pendingFrame = null;
                renderFrame = null;
                pendingWidth = 0;
                pendingHeight = 0;
                renderWidth = 0;
                renderHeight = 0;
                pendingFrameSize = 0;
            }
        });
        mTargetSurface.requestRender();
    }

    private void updateVertices() {
        if (mScreenWidth <= 0 || mScreenHeight <= 0 || mVideoWidth <= 0 || mVideoHeight <= 0) {
            return;
        }
        if (fillScreen) {
            // 铺满：拉伸铺满整个视口
            prog.createBuffers(GLProgram.squareVertices);
            return;
        }
        // 1:1：按实际比例居中，留黑边
        float screenRadio = 1.0f * mScreenHeight / mScreenWidth;
        float videoRadio = 1.0f * mVideoHeight / mVideoWidth;
        if (screenRadio == videoRadio) {
            prog.createBuffers(GLProgram.squareVertices);
        } else if (screenRadio < videoRadio) {
            float widScale = screenRadio / videoRadio;
            prog.createBuffers(new float[]{-widScale, -1.0f, widScale, -1.0f, -widScale, 1.0f, widScale, 1.0f,});
        } else {
            float heightScale = videoRadio / screenRadio;
            prog.createBuffers(new float[]{-1.0f, -heightScale, 1.0f, -heightScale, -1.0f, heightScale, 1.0f, heightScale,});
        }
    }

    public void update(ByteBuffer yuvData, int yuvSize, int width, int height) {
        if (yuvData == null || width <= 0 || height <= 0) {
            return;
        }
        resize(width, height);
        int expectedSize = width * height * 3 / 2;
        if (yuvSize < expectedSize || yuvData.capacity() < expectedSize) {
            Log.w(TAG, "skip invalid yuv frame, yuvSize=" + yuvSize + ", expectedSize=" + expectedSize + ", bufferCapacity=" + yuvData.capacity());
            return;
        }
        synchronized (frameLock) {
            ensureFrameCapacity(expectedSize);
            if (hasPendingFrame) {
                droppedFrameCount++;
            }
            ByteBuffer src = yuvData.duplicate();
            src.position(0);
            src.limit(expectedSize);
            pendingFrame.clear();
            pendingFrame.put(src);
            pendingFrame.flip();
            pendingWidth = width;
            pendingHeight = height;
            pendingFrameSize = expectedSize;
            hasPendingFrame = true;
        }
        mTargetSurface.requestRender();
    }

    public void release() {
        prog.release();
    }

    private void ensureFrameCapacity(int expectedSize) {
        if (pendingFrame == null || pendingFrame.capacity() != expectedSize) {
            pendingFrame = ByteBuffer.allocateDirect(expectedSize);
        }
        if (renderFrame == null || renderFrame.capacity() != expectedSize) {
            renderFrame = ByteBuffer.allocateDirect(expectedSize);
        }
    }

    private ByteBuffer slicePlane(ByteBuffer buffer, int offset, int size) {
        ByteBuffer plane = buffer.duplicate();
        plane.position(offset);
        plane.limit(offset + size);
        return plane.slice();
    }
}
