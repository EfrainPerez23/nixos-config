# Patch for Dynamic Music Pill to:
# 1) Render on EVERY Dash to Panel top bar across monitors (sharing a single cava process).
# 2) Open the expanded preview smoothly on hover without flicker and hide cleanly on leave.

{ gnomeExtensions, python3 }:

gnomeExtensions.dynamic-music-pill.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    extDir="$out/share/gnome-shell/extensions/dynamic-music-pill@andbal"
    ${python3}/bin/python3 ${./patch-dmp.py} \
      "$extDir/src/controller.js" \
      "$extDir/src/uiMusicPill.js" \
      "$extDir/src/uiExpandedPlayer.js" \
      "$extDir/src/visualizerEngine.js" \
      "$extDir/src/utils.js"
    cp ${./extension.js} "$extDir/extension.js"
  '';
})
