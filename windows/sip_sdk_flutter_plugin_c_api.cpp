#include "include/sip_sdk_flutter/sip_sdk_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "sip_sdk_flutter_plugin.h"

void SipSdkFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  sip_sdk_flutter::SipSdkFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
