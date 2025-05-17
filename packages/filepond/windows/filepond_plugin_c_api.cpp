#include "include/filepond/filepond_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "filepond_plugin.h"

void FilepondPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  filepond::FilepondPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
