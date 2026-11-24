# Patch for Coverflow Alt-Tab on GNOME Shell 51+:
# 1) Prevent _next()/_previous() from calling dimBackground() and crashing in
#    _raiseIcons() during the 150ms initial delay before show() creates icons.
# 2) Guarantee switcher teardown with a fallback timeout in animateClosed() so
#    interrupted preview transitions never leave the radial vignette stuck.
# 3) Always destroy any previous switcher, BackgroundManager, and orphaned
#    `coverflow-alt-tab-background-group` actors in Main.uiGroup.

{ gnomeExtensions, python3 }:

gnomeExtensions.coverflow-alt-tab.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    extDir="$out/share/gnome-shell/extensions/CoverflowAltTab@palatis.blogspot.com"
    ${python3}/bin/python3 ${./patch-coverflow.py} \
      "$extDir/switcher.js" \
      "$extDir/platform.js" \
      "$extDir/manager.js"
  '';
})
