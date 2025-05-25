//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <filepond/filepond_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) filepond_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FilepondPlugin");
  filepond_plugin_register_with_registrar(filepond_registrar);
}
