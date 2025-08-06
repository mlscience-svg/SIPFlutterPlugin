package com.sip.flutter.sip_sdk_flutter.view.cameragl;

import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.GLSurfaceView.Renderer;

import java.nio.Buffer;
import java.nio.ByteBuffer;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class YUVRenderer implements Renderer {
    private final GLSurfaceView mTargetSurface;
    private final GLProgram prog = new GLProgram();
    private int mScreenWidth, mScreenHeight;
    private int mVideoWidth, mVideoHeight;
    private ByteBuffer yData;
    private ByteBuffer uData;
    private ByteBuffer vData;

    public YUVRenderer(GLSurfaceView surface) {
        mTargetSurface = surface;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        if (!prog.isProgramBuilt()) {
            prog.buildProgram();
        }
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        mScreenWidth = width;
        mScreenHeight = height;
        GLES20.glViewport(0, 0, width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        synchronized (this) {
            if (yData != null) {
                // reset position, have to be done
                yData.position(0);
                uData.position(0);
                vData.position(0);
                prog.buildTextures(new Buffer[]{yData, uData, vData}, mVideoWidth, mVideoHeight);
                GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
                GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
                prog.drawFrame();
            }
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
            int yarraySize = width * height;
            int uvarraySize = yarraySize / 4;
            synchronized (this) {
                yData = ByteBuffer.allocate(yarraySize);
                uData = ByteBuffer.allocate(uvarraySize);
                vData = ByteBuffer.allocate(uvarraySize);
            }
        }
    }

    public void update(byte[] yuvData, int width, int height) {
        resize(width, height);
        synchronized (this) {
            yData.clear();
            uData.clear();
            vData.clear();
            yData.put(yuvData, 0, yData.capacity());
            uData.put(yuvData, yData.capacity(), uData.capacity());
            vData.put(yuvData, yData.capacity() + uData.capacity(), vData.capacity());
        }
        // request to render
        mTargetSurface.requestRender();
    }
}
