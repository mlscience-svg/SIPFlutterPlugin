package com.sip.flutter.sip_sdk_flutter.view.cameragl;

import android.opengl.GLES20;
import android.util.Log;

import java.nio.Buffer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

public class GLProgram {
    private int mProgram;
    private int positionHandle = -1;
    private int coordHandle = -1;
    private ByteBuffer verticeBuffer;
    private ByteBuffer coordBuffer;

    private int[] yuvHandle = {-1, -1, -1};
    private int[] mTextureID = {-1, -1, -1};

    private int videoWidth = -1;
    private int videoHeight = -1;
    private static final int SIZEOF_FLOAT = 4;

    private int mSharpHandle;
    private int mTextureSizeHandle;
    private float mSharpLevel = 5.0f;
    private float[] textureSize;
    private FloatBuffer TEXTURE_SIZE;

    public boolean isProgramBuilt() {
        return mProgram > 0;
    }

    public void buildProgram() {
        if (mProgram <= 0) {
            mProgram = createProgram(VERTEX_SHADER, FRAGMENT_SHADER);
        }

        positionHandle = GLES20.glGetAttribLocation(mProgram, "vPosition");
        coordHandle = GLES20.glGetAttribLocation(mProgram, "aTextureCoord");
        yuvHandle[0] = GLES20.glGetUniformLocation(mProgram, "textureY");
        yuvHandle[1] = GLES20.glGetUniformLocation(mProgram, "textureU");
        yuvHandle[2] = GLES20.glGetUniformLocation(mProgram, "textureV");

        mSharpHandle = GLES20.glGetUniformLocation(mProgram, "sharpLevel");
        mTextureSizeHandle = GLES20.glGetUniformLocation(mProgram, "mTextureSize");
    }

    public void buildTextures(Buffer[] yuvData, int width, int height) {
        if (width != videoWidth || height != videoHeight) {
            videoWidth = width;
            videoHeight = height;

            textureSize = new float[]{width, height};
            TEXTURE_SIZE = createFloatBuffer(textureSize);

            if (mTextureID[0] >= 0) {
                GLES20.glDeleteTextures(mTextureID.length, mTextureID, 0);
            }
            GLES20.glGenTextures(mTextureID.length, mTextureID, 0);
        }

        for (int i = 0; i < yuvData.length; i++) {
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextureID[i]);
            if (i == 0) {
                GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, videoWidth, videoHeight, 0, GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, yuvData[i]);
                GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
                GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
            } else {
                GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_LUMINANCE, videoWidth / 2, videoHeight / 2, 0, GLES20.GL_LUMINANCE, GLES20.GL_UNSIGNED_BYTE, yuvData[i]);
                GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
                GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
            }
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        }
    }

    /**
     * the YUV data will be converted to RGB by shader.
     */
    public void drawFrame() {
        GLES20.glUseProgram(mProgram);
        GLES20.glVertexAttribPointer(positionHandle, 2, GLES20.GL_FLOAT, false, 2 * SIZEOF_FLOAT, verticeBuffer);
        GLES20.glEnableVertexAttribArray(positionHandle);
        GLES20.glVertexAttribPointer(coordHandle, 2, GLES20.GL_FLOAT, false, 2 * SIZEOF_FLOAT, coordBuffer);
        GLES20.glEnableVertexAttribArray(coordHandle);

        // bind textures
        for (int i = 0; i < mTextureID.length; i++) {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0 + i);
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, mTextureID[i]);
            GLES20.glUniform1i(yuvHandle[i], i);
        }
        GLES20.glUniform1f(mSharpHandle, mSharpLevel);
        GLES20.glUniform2fv(mTextureSizeHandle, 1, TEXTURE_SIZE);

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glFinish();

        GLES20.glDisableVertexAttribArray(positionHandle);
        GLES20.glDisableVertexAttribArray(coordHandle);
    }

    public int createProgram(String vertexSource, String fragmentSource) {
        int vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        int pixelShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);

        int program = GLES20.glCreateProgram();
        if (program != 0) {
            GLES20.glAttachShader(program, vertexShader);
            GLES20.glAttachShader(program, pixelShader);
            GLES20.glLinkProgram(program);
            int[] linkStatus = new int[1];
            GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0);
            if (linkStatus[0] != GLES20.GL_TRUE) {
                Log.e("llx", GLES20.glGetProgramInfoLog(program));
                GLES20.glDeleteProgram(program);
                program = 0;
            }
        }
        return program;
    }

    private int loadShader(int shaderType, String source) {
        int shader = GLES20.glCreateShader(shaderType);
        if (shader != 0) {
            GLES20.glShaderSource(shader, source);
            GLES20.glCompileShader(shader);
            int[] compiled = new int[1];
            GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
            if (compiled[0] == 0) {
                Log.e("llx", GLES20.glGetShaderInfoLog(shader));
                GLES20.glDeleteShader(shader);
                shader = 0;
            }
        }
        return shader;
    }

    void createBuffers(float[] vert) {
        verticeBuffer = ByteBuffer.allocateDirect(vert.length * SIZEOF_FLOAT);
        verticeBuffer.order(ByteOrder.nativeOrder());
        verticeBuffer.asFloatBuffer().put(vert);
        verticeBuffer.position(0);

        if (coordBuffer == null) {
            coordBuffer = ByteBuffer.allocateDirect(coordVertices.length * SIZEOF_FLOAT);
            coordBuffer.order(ByteOrder.nativeOrder());
            coordBuffer.asFloatBuffer().put(coordVertices);
            coordBuffer.position(0);
        }
    }

    public static FloatBuffer createFloatBuffer(float[] coords) {
        // Allocate a direct ByteBuffer, using 4 bytes per float, and copy coords into it.
        ByteBuffer bb = ByteBuffer.allocateDirect(coords.length * SIZEOF_FLOAT);
        bb.order(ByteOrder.nativeOrder());
        FloatBuffer fb = bb.asFloatBuffer();
        fb.put(coords);
        fb.position(0);
        return fb;
    }

    static float[] squareVertices = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f,
    }; // fullscreen

    private static float[] coordVertices = {
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
    };// whole-texture

    private static final String VERTEX_SHADER =
            "attribute vec4 vPosition;\n" +
                    "attribute vec2 aTextureCoord;\n" +
                    "varying vec2 vTextureCoord;\n" +
                    "void main() {\n" +
                    "   gl_Position = vPosition;\n" +
                    "   vTextureCoord = aTextureCoord;\n" +
                    "}\n";

    private static final String FRAGMENT_SHADER =
            "precision mediump float;\n" +
                    "uniform sampler2D textureY;\n" +
                    "uniform sampler2D textureU;\n" +
                    "uniform sampler2D textureV;\n" +
                    "varying vec2 vTextureCoord;\n" +
                    "uniform vec2 mTextureSize;\n" +
                    "uniform float sharpLevel;\n" +
                    "const float LIMIT = 15.0/255.0;\n" +
                    "void main() {\n" +
                    "    vec2 offset0 = vec2(1.0, 1.0) / mTextureSize;\n" +
                    "    vec2 offset1 = vec2(0.0, 1.0) / mTextureSize;\n" +
                    "    vec2 offset2 = vec2(-1.0, 1.0) / mTextureSize;\n" +
                    "    vec2 offset3 = vec2(1.0, 0.0) / mTextureSize;\n" +
                    "    float cTemp0 = texture2D(textureY, vTextureCoord + offset0).r;\n" +
                    "    float cTemp1 = texture2D(textureY, vTextureCoord + offset1).r;\n" +
                    "    float cTemp2 = texture2D(textureY, vTextureCoord + offset2).r;\n" +
                    "    float cTemp3 = texture2D(textureY, vTextureCoord + offset3).r;\n" +
                    "    float cTemp4 = texture2D(textureY, vTextureCoord).r;\n" +
                    "    float cTemp5 = texture2D(textureY, vTextureCoord - offset3).r;\n" +
                    "    float cTemp6 = texture2D(textureY, vTextureCoord - offset2).r;\n" +
                    "    float cTemp7 = texture2D(textureY, vTextureCoord - offset1).r;\n" +
                    "    float cTemp8 = texture2D(textureY, vTextureCoord - offset0).r;\n" +
                    "    float y = cTemp4 + min(LIMIT, max(-LIMIT, (cTemp4-(cTemp0+cTemp2+cTemp6+cTemp8+(cTemp1+cTemp3+cTemp5+cTemp7)*2.0+cTemp4*4.0)/16.0)*sharpLevel));\n" +
                    "    float u = texture2D(textureU, vTextureCoord).r;\n" +
                    "    float v = texture2D(textureV, vTextureCoord).r;\n" +
                    "    \n" +
                    "    float R = y + (v - 0.5) *  1.402;\n" +
                    "    float G = y - ((u - 0.5) * 0.3441) - (v - 0.5) * 0.7141;\n" +
                    "    float B = y + (u - 0.5) *  1.772;\n" +
                    "    \n" +
                    "    gl_FragColor = vec4(R, G, B, 1.0);" +
                    "}\n";
}