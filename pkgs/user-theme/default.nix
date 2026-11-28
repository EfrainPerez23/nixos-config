# Patch for User Themes to stay enabled on the lock screen (`unlock-dialog` session mode),
# preventing GNOME Shell from unloading and re-parsing the full Colloid Catppuccin CSS
# (~5-7 s freeze) on every lock/suspend and unlock cycle.

{ gnomeExtensions, python3 }:

gnomeExtensions.user-themes.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    ${python3}/bin/python3 ${./patch-user-theme.py} \
      "$out/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/metadata.json"
  '';
})
