# Custom declarative options (`my.*`) configurable per host in `hosts/<profile>/default.nix`

{ lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.my = {
    user = {
      name = mkOption {
        type = types.str;
        description = "Primary system username.";
      };

      fullName = mkOption {
        type = types.str;
        default = "";
        description = "Full name of the primary user.";
      };

      flakeDir = mkOption {
        type = types.str;
        description = "Local path to this flake repository (used by `nh os switch`).";
      };
    };

    locale = {
      timeZone = mkOption {
        type = types.str;
        default = "UTC";
        description = "System timezone.";
      };

      defaultLocale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "Primary system locale.";
      };

      extraLocale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "Regional formatting locale (currency, dates, measurements, etc.).";
      };

      xkbLayout = mkOption {
        type = types.str;
        default = "us";
        description = "Keyboard layout.";
      };

      xkbVariant = mkOption {
        type = types.str;
        default = "";
        description = "Keyboard layout variant.";
      };
    };

    desktop = {
      gnome.enable = mkEnableOption "GNOME desktop environment with Catppuccin Mocha theme";
      guake.enable = mkEnableOption "Guake drop-down terminal adapted for GNOME Wayland";
      vicinae.enable = mkEnableOption "Vicinae launcher with user systemd daemon";
    };

    boot = {
      loader = mkOption {
        type = types.enum [
          "grub"
          "systemd-boot"
        ];
        default = "grub";
        description = "Bootloader for this host (`grub` supports dual-boot across one or multiple disks; `systemd-boot` is lighter for dedicated disks).";
      };

      efiMountPoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "EFI mount point. When `null`, auto-detected from `hardware-configuration.nix` (`/boot/efi` or `/boot`).";
      };

      useOSProber = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically detect other OSes (such as Windows on the same or another disk) in GRUB.";
      };

      customLogo = mkOption {
        type = types.bool;
        default = true;
        description = "Use the custom Catppuccin GRUB theme with dual-boot logo (`assets/grub-logo.png`).";
      };

      bootvine = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bootvine (live systemd dependency tree on boot/shutdown).";
      };
    };

    hardware = {
      gpu = mkOption {
        type = types.enum [
          "none"
          "intel"
          "amd"
          "nvidia"
        ];
        default = "none";
        description = "GPU profile for this host (`intel`, `amd`, `nvidia` for RTX 20+, or `none`).";
      };

      nvidiaOpen = mkOption {
        type = types.bool;
        default = true;
        description = "Use the open-source NVIDIA kernel module (recommended for RTX 2000+ / GTX 1600+; set to `false` for older cards).";
      };
    };

    apps = {
      browsers.enable = mkEnableOption "Google Chrome (Wayland/VA-API) and Firefox";
      antigravity.enable = mkEnableOption "Antigravity IDE (FHS) and Antigravity CLI";
    };
  };
}
