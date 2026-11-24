# Patch for Rounded Window Corners Reborn on GNOME Shell 51+:
# Keep each window's Shadow Actor stacked directly below its MetaWindowActor
# even when extensions like Coverflow Alt-Tab temporarily hide window actors
# during a window restack (switching from a floating window to a maximized one),
# and re-sync shadow z-order when a hidden window actor becomes visible again.

{ gnomeExtensions, python3 }:

gnomeExtensions.rounded-window-corners-reborn.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    extDir="$out/share/gnome-shell/extensions/rounded-window-corners@fxgn"
    ${python3}/bin/python3 ${./patch-rwc.py} \
      "$extDir/manager/event_handlers.js" \
      "$extDir/manager/event_manager.js"
  '';
})
