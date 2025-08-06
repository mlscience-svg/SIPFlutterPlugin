import 'package:flutter_test/flutter_test.dart';
import 'package:sip_sdk_flutter/sip_sdk_flutter.dart';
import 'package:sip_sdk_flutter/sip_sdk_flutter_platform_interface.dart';
import 'package:sip_sdk_flutter/sip_sdk_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSipSdkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements SipSdkFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SipSdkFlutterPlatform initialPlatform = SipSdkFlutterPlatform.instance;

  test('$MethodChannelSipSdkFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSipSdkFlutter>());
  });

  test('getPlatformVersion', () async {
    SipSdkFlutter sipSdkFlutterPlugin = SipSdkFlutter();
    MockSipSdkFlutterPlatform fakePlatform = MockSipSdkFlutterPlatform();
    SipSdkFlutterPlatform.instance = fakePlatform;

    expect(await sipSdkFlutterPlugin.getPlatformVersion(), '42');
  });
}
