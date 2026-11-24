# Custom packages and patches index (exposed via `pkgs.custom.*` and `nix build .#<pkg>`)

{ pkgs }:

{
  azclock-multimonitor = pkgs.callPackage ./azclock-multimonitor { };
  catppuccin-grub-custom = pkgs.callPackage ./catppuccin-grub-custom { };
  colloid-catppuccin-theme = pkgs.callPackage ./colloid-catppuccin-theme { };
  coverflow-alt-tab = pkgs.callPackage ./coverflow-alt-tab { };
  dynamic-music-pill = pkgs.callPackage ./dynamic-music-pill { };
  guake-helper = pkgs.callPackage ./guake-helper { };
  guake-toggle = pkgs.callPackage ./guake-toggle { };
  quick-settings-audio-panel = pkgs.callPackage ./quick-settings-audio-panel { };
  rounded-window-corners = pkgs.callPackage ./rounded-window-corners { };
}
