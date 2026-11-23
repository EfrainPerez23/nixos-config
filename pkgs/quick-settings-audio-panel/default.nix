# Patch for Quick Settings Audio Panel (QSAP) on GNOME Shell 51+:
# 1) Avoid `old_menu.actor.clear_actions()` in LibPanel.replace_menu(), which strips
#    StFocusManager's internal ClutterKeyController and causes a use-after-free SIGSEGV
#    when locking the screen / disabling extensions.
# 2) Guard `lookup_device_from_stream()` against null in `_patch_show_current_device()`
#    so re-enabling after unlock never throws a TypeError while audio streams settle.

{ gnomeExtensions, python3 }:

gnomeExtensions.quick-settings-audio-panel.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    extDir="$out/share/gnome-shell/extensions/quick-settings-audio-panel@rayzeq.github.io"
    ${python3}/bin/python3 ${./patch-qsap.py} "$extDir/libs/libpanel/main.js" "$extDir/extension.js"
  '';
})
