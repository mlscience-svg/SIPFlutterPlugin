#ifndef FLUTTER_PLUGIN_SIP_SDK_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_SIP_SDK_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace sip_sdk_flutter {

class SipSdkFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SipSdkFlutterPlugin();

  virtual ~SipSdkFlutterPlugin();

  // Disallow copy and assign.
  SipSdkFlutterPlugin(const SipSdkFlutterPlugin&) = delete;
  SipSdkFlutterPlugin& operator=(const SipSdkFlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace sip_sdk_flutter

#endif  // FLUTTER_PLUGIN_SIP_SDK_FLUTTER_PLUGIN_H_
