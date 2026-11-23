import sys

libpanel_main_path, extension_path = sys.argv[1], sys.argv[2]

# 1) Patch libs/libpanel/main.js: only remove PanelMenu.Button's _keyController
# instead of calling clear_actions(), which frees StFocusManager's internal
# ClutterKeyController on GNOME Shell 51+ and triggers a SIGSEGV on destroy.
with open(libpanel_main_path, "r") as f:
    main_js = f.read()

old_clear = (
    "        // let's hope there wasn't any other action\n"
    "        old_menu.actor.clear_actions();"
)
new_clear = (
    "        // Only remove PanelMenu.Button's _keyController so StFocusManager's\n"
    "        // internal ClutterKeyController (GNOME 51+) is preserved.\n"
    "        if (quick_settings._keyController?.get_actor?.() === old_menu.actor)\n"
    "            old_menu.actor.remove_action(quick_settings._keyController);"
)

assert old_clear in main_js, "clear_actions() block not found in libs/libpanel/main.js"
main_js = main_js.replace(old_clear, new_clear, 1)

with open(libpanel_main_path, "w") as f:
    f.write(main_js)

# 2) Patch extension.js: guard lookup_device_from_stream() against null
with open(extension_path, "r") as f:
    ext_js = f.read()

old_device_patch = (
    '        slider._qsap_callback = slider._control.connect(signal_name, () => {\n'
    '            const device_id = slider._control.lookup_device_from_stream(slider._stream).get_id();\n'
    '            // using the item\'s text allow for compatibility with extensions that changes it, let\'s hope this won\'t break\n'
    '            slider._deviceItems\n'
    '                .get(device_id)\n'
    '                .label.bind_property("text", label, "text", GObject.BindingFlags.SYNC_CREATE);\n'
    '        });\n'
    '        if (slider._stream) {\n'
    '            const device_id = slider._control.lookup_device_from_stream(slider._stream).get_id();\n'
    '            slider._deviceItems\n'
    '                .get(device_id)\n'
    '                .label.bind_property("text", label, "text", GObject.BindingFlags.SYNC_CREATE);\n'
    '        }'
)
new_device_patch = (
    '        slider._qsap_callback = slider._control.connect(signal_name, () => {\n'
    '            const device = slider._stream && slider._control.lookup_device_from_stream(slider._stream);\n'
    '            const device_item = device && slider._deviceItems.get(device.get_id());\n'
    '            // using the item\'s text allow for compatibility with extensions that changes it, let\'s hope this won\'t break\n'
    '            device_item?.label.bind_property("text", label, "text", GObject.BindingFlags.SYNC_CREATE);\n'
    '        });\n'
    '        if (slider._stream) {\n'
    '            const device = slider._control.lookup_device_from_stream(slider._stream);\n'
    '            const device_item = device && slider._deviceItems.get(device.get_id());\n'
    '            device_item?.label.bind_property("text", label, "text", GObject.BindingFlags.SYNC_CREATE);\n'
    '        }'
)

assert old_device_patch in ext_js, "lookup_device_from_stream block not found in extension.js"
ext_js = ext_js.replace(old_device_patch, new_device_patch, 1)

with open(extension_path, "w") as f:
    f.write(ext_js)
