# System boot: automatic EFI mount detection (/boot/efi vs /boot) + GRUB/systemd-boot + Bootvine

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.boot;

  # Auto-detect EFI mount point from `hardware-configuration.nix`:
  # - "/boot/efi" when sharing a small EFI partition (e.g. Windows dual-boot on the same disk)
  # - "/boot" when NixOS uses its own dedicated EFI partition
  efiMountPoint =
    if cfg.efiMountPoint != null then
      cfg.efiMountPoint
    else if config.fileSystems ? "/boot/efi" then
      "/boot/efi"
    else
      "/boot";
in
{
  imports = [
    "${inputs.bootvine}/nix/nixos-module.nix"
  ];

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = efiMountPoint;
      };

      grub = lib.mkIf (cfg.loader == "grub") {
        enable = true;
        device = "nodev";
        efiSupport = true;
        inherit (cfg) useOSProber;
        configurationLimit = 3;
        theme = if cfg.customLogo then pkgs.custom.catppuccin-grub-custom else pkgs.catppuccin-grub;
      };

      systemd-boot = {
        enable = cfg.loader == "systemd-boot";
        configurationLimit = 3;
      };
    };

    consoleLogLevel = lib.mkIf cfg.bootvine 3;
  };

  # Bootvine: replaces [ OK ] boot logs with a live systemd dependency tree
  services.bootvine.enable = cfg.bootvine;

  # Print detected disk/boot layout during `nixos-rebuild switch` / `just apply`
  system.activationScripts.bootLayoutInfo = {
    deps = [ ];
    text = ''
      ROOT_SRC="$(${pkgs.util-linux}/bin/findmnt -no SOURCE / 2>/dev/null | ${pkgs.gnused}/bin/sed 's/\[.*\]//' || true)"
      ROOT_DISK="$(${pkgs.util-linux}/bin/lsblk -no PKNAME "$ROOT_SRC" 2>/dev/null | ${pkgs.coreutils}/bin/head -n1 || true)"

      if [ -n "$ROOT_DISK" ] && [ -b "/dev/$ROOT_DISK" ]; then
        if ${pkgs.util-linux}/bin/lsblk -nr -o FSTYPE "/dev/$ROOT_DISK" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qiE '^(ntfs|BitLocker)$'; then
          echo "💿 [boot] Running NixOS on a shared/partitioned disk (/dev/$ROOT_DISK) alongside Windows | EFI: ${efiMountPoint} | Loader: ${cfg.loader}"
        elif [ "${efiMountPoint}" = "/boot/efi" ]; then
          echo "💿 [boot] Running NixOS on a partitioned disk (/dev/$ROOT_DISK, shared EFI) | EFI: ${efiMountPoint} | Loader: ${cfg.loader}"
        elif ${pkgs.util-linux}/bin/lsblk -nr -o PKNAME,FSTYPE 2>/dev/null | ${pkgs.gnugrep}/bin/grep -vi "^$ROOT_DISK " | ${pkgs.gnugrep}/bin/grep -qiE ' (ntfs|BitLocker)$'; then
          echo "💿 [boot] Running NixOS on a dedicated disk (/dev/$ROOT_DISK) + Windows on another disk | EFI: ${efiMountPoint} | Loader: ${cfg.loader}"
        else
          echo "💿 [boot] Running NixOS on a dedicated disk (/dev/$ROOT_DISK) | EFI: ${efiMountPoint} | Loader: ${cfg.loader}"
        fi
      else
        if [ "${efiMountPoint}" = "/boot/efi" ]; then
          echo "💿 [boot] Boot layout detected for shared/partitioned disk | EFI: ${efiMountPoint} | Loader: ${cfg.loader}"
        else
          echo "💿 [boot] Boot layout detected for dedicated disk | EFI: ${efiMountPoint} | Loader: ${cfg.loader}"
        fi
      fi
    '';
  };
}
