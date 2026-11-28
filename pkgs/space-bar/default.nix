# Patch for Space Bar to keep its dynamic stylesheet loaded across lock/unlock cycles,
# avoiding a redundant full StTheme CSS recalculation (~4-6 s freeze) every time the screen unlocks.

{ gnomeExtensions, python3 }:

gnomeExtensions.space-bar.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    ${python3}/bin/python3 ${./patch-space-bar.py} \
      "$out/share/gnome-shell/extensions/space-bar@luchrioh/services/Styles.js"
  '';
})
