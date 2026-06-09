package com.sip.flutter.sip_sdk_flutter.view.cameragl;

import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.GLSurfaceView.Renderer;
import android.util.Log;

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
    private int pendingWidth;
    private int pendingHeight;
    private int pendingFrameSize;
    private boolean hasPendingFrame;
    private boolean hasUploadedFrame;
    private int droppedFrameCount;

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

        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        if (hasUploadedFrame) {
            prog.drawFrame();
        }
    }

    private void resize(int width, int height) {
        // 初始化容器
        if (width != mVideoWidth || height != mVideoHeight) {
            // 调整比例
            if (mScreenWidth > 0 && mScreenHeight > 0) {
                float screenRadio = 1.0f * mScreenHeight / mScreenWidth;
                float videoRadio = 1.0f * height / width;
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

            this.mVideoWidth = width;
            this.mVideoHeight = height;
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
