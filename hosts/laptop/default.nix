# Host control panel: laptop (Intel + GNOME Catppuccin Mocha)
# Personal settings (username, full name, hostname, timezone) are loaded from `local/local.nix` (gitignored).

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./wifi-intel.nix
  ];

  # Hardware profile and enabled features for this machine
  my = {
    hardware.gpu = "intel"; # "intel" | "amd" | "nvidia" | "none"

    desktop = {
      gnome.enable = true;
      guake.enable = true;
      vicinae.enable = true;
    };

    apps = {
      browsers.enable = true;
      antigravity.enable = true;
    };
  };

  # Initial NixOS state version (do not change after installation)
  system.stateVersion = "26.05";
}
