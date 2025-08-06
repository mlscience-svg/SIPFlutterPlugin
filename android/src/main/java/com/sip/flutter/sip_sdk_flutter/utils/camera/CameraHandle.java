package com.sip.flutter.sip_sdk_flutter.utils.camera;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.util.Log;
import android.util.Size;
import android.view.Surface;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import com.openh264.JNIOpenH264Manage;
import com.sip.flutter.sip_sdk_flutter.SipSdkFlutterPlugin;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class CameraHandle {
    private final String TAG = CameraHandle.class.getName();
    private CameraManager cameraManager;
    private CameraDevice cameraDevice;
    private CameraCaptureSession captureSession;
    private ImageReader imageReader;
    //保存摄像头对应的目标分辨率大小
    private final Map<String, CameraInfo> targetResolutionMap = new HashMap<>();
    //当前摄像头
    private CameraInfo currentCameraInfo = null;
    private final List<CameraStateChangeCallback> callbacks = new ArrayList<>();

    private static class Instance {
        private static final CameraHandle instance = new CameraHandle();
    }

    public static CameraHandle instance() {
        return Instance.instance;
    }

    public void addStateChangeCallback(CameraStateChangeCallback callback) {
        if (!callbacks.contains(callback)) {
            callbacks.add(callback);
        }
    }

    public void removeStateChangeCallback(CameraStateChangeCallback callback) {
        callbacks.remove(callback);
    }

    private int calculateRotation(CameraCharacteristics characteristics, Context context) {
        Integer sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
        Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
        if (sensorOrientation == null || facing == null) return 0;

        int deviceRotation = ((WindowManager) context.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay().getRotation();

        int deviceDegrees;
        switch (deviceRotation) {
            case Surface.ROTATION_90:
                deviceDegrees = 90;
                break;
            case Surface.ROTATION_180:
                deviceDegrees = 180;
                break;
            case Surface.ROTATION_270:
                deviceDegrees = 270;
                break;
            case Surface.ROTATION_0:
            default:
                deviceDegrees = 0;
                break;
        }
        if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
            return (sensorOrientation + deviceDegrees) % 360;
        } else {
            return (sensorOrientation - deviceDegrees + 360) % 360;
        }
    }

    public CameraHandle() {
        try {
            cameraManager = (CameraManager) SipSdkFlutterPlugin.context.getSystemService(Context.CAMERA_SERVICE);
            for (String cameraId : cameraManager.getCameraIdList()) {
                CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(cameraId);
                Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
                if (facing != null) {
                    StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
                    Size[] sizes = null;
                    if (map != null) {
                        sizes = map.getOutputSizes(ImageFormat.YUV_420_888);
                    }
                    CameraInfo cameraInfo = new CameraInfo();
                    cameraInfo.cameraId = cameraId;
                    cameraInfo.facing = facing;
                    cameraInfo.sizes = sizes;
                    cameraInfo.rotation = calculateRotation(characteristics, SipSdkFlutterPlugin.context);
                    targetResolutionMap.put(cameraId, cameraInfo);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Get Camera Info Error", e);
        }
    }

    public void open(int index, int width, int height) {
        if (ActivityCompat.checkSelfPermission(SipSdkFlutterPlugin.context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        try {
            //先关闭一下
            close();
            CameraInfo cameraInfo = null;
            for (Map.Entry<String, CameraInfo> entry : targetResolutionMap.entrySet()) {
                CameraInfo info = entry.getValue();
                if (index == 0) {
                    if (CameraCharacteristics.LENS_FACING_BACK == info.facing) {
                        cameraInfo = info;
                        break;
                    }
                } else {
                    if (CameraCharacteristics.LENS_FACING_FRONT == info.facing) {
                        cameraInfo = info;
                        break;
                    }
                }
            }

            if (cameraInfo == null) {
                Map.Entry<String, CameraInfo> firstEntry = targetResolutionMap.entrySet().iterator().next();
                cameraInfo = firstEntry.getValue();
            }

            if (cameraInfo == null) {
                return;
            }
            Size previewSize = selectResolution(cameraInfo.sizes, width, height);
            setupImageReader(previewSize);
            cameraInfo.previewSize = previewSize;
            if (ActivityCompat.checkSelfPermission(SipSdkFlutterPlugin.context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                return;
            }
            currentCameraInfo = cameraInfo;
            cameraManager.openCamera(cameraInfo.cameraId, new CameraDevice.StateCallback() {
                @Override
                public void onOpened(@NonNull CameraDevice camera) {
                    cameraDevice = camera;
                    createCameraCaptureSession();
                    for (CameraStateChangeCallback callback : callbacks) {
                        callback.onStateChange(true);
                    }
                }

                @Override
                public void onDisconnected(@NonNull CameraDevice camera) {
                    camera.close();
                    cameraDevice = null;
                    for (CameraStateChangeCallback callback : callbacks) {
                        callback.onStateChange(false);
                    }
                }

                @Override
                public void onError(@NonNull CameraDevice camera, int error) {
                    camera.close();
                    cameraDevice = null;
                    Log.e(TAG, "Camera error: " + error);
                    for (CameraStateChangeCallback callback : callbacks) {
                        callback.onStateChange(false);
                    }
                }
            }, null);
        } catch (CameraAccessException e) {
            Log.e(TAG, "Open Camera Info Error", e);
        }
    }

    private void setupImageReader(Size previewSize) {
        imageReader = ImageReader.newInstance(previewSize.getWidth(), previewSize.getHeight(), ImageFormat.YUV_420_888, 2);
        // 不设置回调监听器
    }

    private void createCameraCaptureSession() {
        try {
            Surface imageReaderSurface = imageReader.getSurface();
            cameraDevice.createCaptureSession(
                    Collections.singletonList(imageReaderSurface),
                    new CameraCaptureSession.StateCallback() {
                        @Override
                        public void onConfigured(@NonNull CameraCaptureSession session) {
                            captureSession = session;
                            try {
                                CaptureRequest.Builder captureRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
                                captureRequestBuilder.addTarget(imageReaderSurface);
                                captureSession.setRepeatingRequest(captureRequestBuilder.build(), null, null);
                            } catch (CameraAccessException e) {
                                Log.e(TAG, "Create Camera Capture Session", e);
                            }
                        }

                        @Override
                        public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                            Log.e(TAG, "Capture session configuration failed.");
                        }
                    },
                    null
            );
        } catch (CameraAccessException e) {
            Log.e(TAG, "Create Camera Capture Session", e);
        }
    }

    // 主动获取图像的方法
    public Image getLatestImage() {
        if (imageReader != null) {
            return imageReader.acquireLatestImage(); // 获取最新的图像
        }
        return null;
    }

    public byte[] imageToI420() {
        Image image = getLatestImage();
        if (image == null) return null;

        Image.Plane[] planes = image.getPlanes();
        ByteBuffer yBuf = planes[0].getBuffer();
        ByteBuffer uBuf = planes[1].getBuffer();
        ByteBuffer vBuf = planes[2].getBuffer();

        int width = image.getWidth();
        int height = image.getHeight();

        int yStride = planes[0].getRowStride();
        int uStride = planes[1].getRowStride();
        int uPixelStride = planes[1].getPixelStride();
        int vStride = planes[2].getRowStride();
        int vPixelStride = planes[2].getPixelStride();

        int rotation = getCurrentCameraInfo().rotation;

        byte[] result = JNIOpenH264Manage.yuvToI420AndRotate(yBuf,
                yStride,
                uBuf,
                uStride,
                uPixelStride,
                vBuf,
                vStride,
                vPixelStride,
                width,
                height,
                rotation);
        image.close();
        return result;
    }

    private Size selectResolution(Size[] sizes, int targetWidth, int targetHeight) {
        Size closestSize = null;
        int minDiff = Integer.MAX_VALUE;

        for (Size size : sizes) {
            int width = size.getWidth();
            int height = size.getHeight();

            // 完全匹配
            if (width == targetWidth && height == targetHeight) {
                return size;
            }

            // 计算宽高差的绝对值之和
            int diff = Math.abs(width - targetWidth) + Math.abs(height - targetHeight);
            if (diff < minDiff) {
                minDiff = diff;
                closestSize = size;
            }
        }
        return closestSize;
    }

    public CameraInfo getCurrentCameraInfo() {
        return currentCameraInfo;
    }

    public void close() {
        if (captureSession != null) {
            captureSession.close();
            captureSession = null;
        }
        if (cameraDevice != null) {
            cameraDevice.close();
            cameraDevice = null;
        }
        if (imageReader != null) {
            imageReader.close();
            imageReader = null;
        }
        for (CameraStateChangeCallback callback : callbacks) {
            callback.onStateChange(false);
        }
    }
}