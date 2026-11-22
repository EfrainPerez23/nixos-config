# Patch for Desktop Clock (azclock) to hide clocks for disconnected monitors
# and render one identical clock per connected monitor without overlap.

{ gnomeExtensions, python3 }:

gnomeExtensions.desktop-clock.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    ${python3}/bin/python3 ${./patch-azclock.py} "$out/share/gnome-shell/extensions/azclock@azclock.gitlab.com/extension.js"
  '';
})
