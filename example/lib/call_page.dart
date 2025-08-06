import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_camera_config.dart';
import 'package:sip_sdk_flutter/entitys/sip_sdk_constants.dart';
import 'package:sip_sdk_flutter_example/sip_manage.dart';

// 可选中状态的圆形按钮
class CircleToggleButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color bgColor;
  final Color selectedBgColor;
  final Color iconColor;
  final Color selectedIconColor;
  final Color borderColor;

  final double size;
  final VoidCallback? onPressed;

  const CircleToggleButton({
    super.key,
    required this.selected,
    required this.icon,
    this.bgColor = Colors.transparent,
    this.selectedBgColor = Colors.blue,
    this.iconColor = Colors.white,
    this.selectedIconColor = Colors.white,
    this.borderColor = Colors.white,
    this.size = 60,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: selectedBgColor.withOpacity(0.3),
      highlightColor: Colors.transparent,
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? selectedBgColor : bgColor,
          shape: BoxShape.circle,
          border: selected ? null : Border.all(color: borderColor, width: 2),
        ),
        child: Icon(
          icon,
          color: selected ? selectedIconColor : iconColor,
          size: 28,
        ),
      ),
    );
  }
}

class CallPage extends StatefulWidget {
  final int direction;
  final int callType;
  final String? callUUID;
  final String? username;
  final String? remoteIp;
  final Map<String, String>? headers;
  final bool? transmitVideo;
  final bool? transmitSound;

  const CallPage({
    super.key,
    required this.direction,
    required this.callType,
    this.callUUID,
    this.username,
    this.remoteIp,
    this.headers,
    this.transmitVideo,
    this.transmitSound,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late String callUUID;
  bool showAnswerButton = false;

  // 按钮状态
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isCameraOn = false;
  int index = 1;

  // 控制原生视图显示，退出时先隐藏再销毁，避免闪烁缩小
  bool showVideoComponentView = true;

  // SIP呼叫回调
  SIPListener? sipListener;

  @override
  void initState() {
    super.initState();
    if (widget.direction == 0) {
      // 主动呼叫
      if (widget.callType == SIPSDKConstants.SDK_CALL_TYPE_SERVER) {
        SIPManage().call(widget.username!, widget.headers ?? {}).then((value) {
          callUUID = value!;
        });
      } else {
        SIPManage()
            .callIP(widget.remoteIp!, widget.headers ?? {})
            .then((value) {
          callUUID = value!;
        });
      }
    } else {
      // 被叫
      setState(() {
        showAnswerButton = true;
      });
      callUUID = widget.callUUID ?? "";
    }

    sipListener = SIPListener(
      onCallState: (String uuid, int state) {
        if (uuid == callUUID) {
          if (state == SIPSDKConstants.CALL_STATE_CONFIRMED) {
            //呼叫连接打开摄像头
            SIPManage().cameraOpen(SIPSDKCameraConfig(
              index: index,
              width: 640,
              height: 480,
            ));
          } else if (state == SIPSDKConstants.CALL_STATE_DISCONNECTED) {
            closePage();
          }
        }
      },
      onCameraStateChange: (bool state) {
        setState(() {
          isCameraOn = state;
        });
      },
    );
    SIPManage().addListener(sipListener!);

    SIPManage().isMute().then((value) {
      setState(() {
        isMuted = value ?? false;
      });
    });

    SIPManage().isSpeaker().then((value) {
      setState(() {
        isSpeakerOn = value ?? true;
      });
    });
    // 请求权限
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    // 摄像头/麦克风权限
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  void closePage() {
    setState(() {
      showVideoComponentView = false;
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    //移除监听
    SIPManage().removeListener(sipListener!);
    //not mute
    SIPManage().setMute(false);
    //speaker
    SIPManage().setSpeaker(true);
    //关闭摄像头
    SIPManage().cameraClose();
    //挂断所有呼叫
    SIPManage().hangup(200);
    super.dispose();
  }

  Widget videoComponentView() {
    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: 'com.sip.flutter/VideoComponentView',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'com.sip.flutter/VideoComponentView',
            layoutDirection: TextDirection.ltr,
            creationParams: {},
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (Platform.isIOS) {
      return const UiKitView(
        viewType: 'com.sip.flutter/VideoComponentView',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{'initParams': ''},
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      /*
      * If using HarmonyOS, you need to use the HarmonyOS Flutter SDK.
      * https://gitcode.com/openharmony-tpc/flutter_flutter/tree/3.22.0-ohos
      **/
      return const OhosView(
        viewType: 'com.sip.flutter/VideoComponentView',
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{'initParams': ''},
        creationParamsCodec: StandardMessageCodec(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (showVideoComponentView)
            videoComponentView()
          else
            Container(color: Colors.black), // 占位，避免跳闪
          // 底部悬浮按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行：静音、免提、摄像头
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        CircleToggleButton(
                          selected: isMuted,
                          icon: isMuted ? Icons.mic_off : Icons.mic,
                          selectedBgColor: Colors.white,
                          selectedIconColor: Colors.black,
                          onPressed: () {
                            SIPManage().setMute(!isMuted);
                            SIPManage().isMute().then((value) {
                              setState(() {
                                isMuted = value ?? false;
                              });
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text("静音", style: TextStyle(color: Colors.white))
                      ],
                    ),
                    Column(
                      children: [
                        CircleToggleButton(
                          selected: isSpeakerOn,
                          icon: Icons.volume_up,
                          selectedBgColor: Colors.white,
                          selectedIconColor: Colors.black,
                          onPressed: () {
                            SIPManage().setSpeaker(!isSpeakerOn);
                            SIPManage().isSpeaker().then((value) {
                              setState(() {
                                isSpeakerOn = value ?? true;
                              });
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text("免提", style: TextStyle(color: Colors.white))
                      ],
                    ),
                    Column(
                      children: [
                        CircleToggleButton(
                          selected: isCameraOn,
                          icon: Icons.videocam,
                          selectedBgColor: Colors.white,
                          selectedIconColor: Colors.black,
                          onPressed: () {
                            if (isCameraOn) {
                              SIPManage().cameraClose();
                              setState(() {
                                isCameraOn = false;
                              });
                            } else {
                              SIPManage().cameraOpen(SIPSDKCameraConfig(
                                index: index,
                                width: 640,
                                height: 480,
                              ));
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text("摄像头", style: TextStyle(color: Colors.white))
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // 第二行：开锁、接听、挂断、切换摄像头
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleToggleButton(
                      selected: false,
                      icon: Icons.lock_open,
                      selectedBgColor: Colors.blue,
                      onPressed: () {
                        //发送开锁消息
                        if (widget.callType ==
                            SIPSDKConstants.SDK_CALL_TYPE_IP) {
                          SIPManage().sendMessageIP(widget.remoteIp!, "unlock");
                        } else {
                          SIPManage().sendMessage(widget.username!, "unlock");
                        }
                      },
                    ),
                    if (showAnswerButton)
                      CircleToggleButton(
                        selected: false,
                        icon: Icons.call,
                        bgColor: Colors.green,
                        borderColor: Colors.green,
                        onPressed: () {
                          SIPManage().answer(200);
                          setState(() {
                            showAnswerButton = false;
                          });
                        },
                      ),
                    CircleToggleButton(
                      selected: false,
                      icon: Icons.call_end,
                      bgColor: Colors.red,
                      borderColor: Colors.red,
                      onPressed: () {
                        closePage();
                      },
                    ),
                    CircleToggleButton(
                      selected: false,
                      icon: Icons.cameraswitch,
                      selectedBgColor: Colors.grey,
                      onPressed: () {
                        index = index == 1 ? 0 : 1;
                        SIPManage().cameraOpen(SIPSDKCameraConfig(
                          index: index,
                          width: 640,
                          height: 480,
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void onPlatformViewCreated(int id) {}
