# Laptop-specific hardware fix:
# Automatically resets Intel 8265 Wi-Fi (PCI 0000:02:00.0) if iwlwifi fails on boot or resume (error -110)

{ pkgs, ... }:

let
  iwlwifiResetScript = pkgs.writeShellScript "iwlwifi-reset" ''
    PCI_DEV="/sys/bus/pci/devices/0000:02:00.0"

    if [ ! -d "$PCI_DEV" ]; then
      exit 0
    fi

    # Wait briefly in case firmware is still finishing initialization
    for _ in 1 2 3 4 5 6; do
      if [ -d "$PCI_DEV/net" ] && [ -n "$(${pkgs.coreutils}/bin/ls -A "$PCI_DEV/net" 2>/dev/null)" ]; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.5
    done

    echo "Wi-Fi (0000:02:00.0) not detected; resetting PCI device and reloading iwlwifi..."
    ${pkgs.kmod}/bin/modprobe -r iwlmvm 2>/dev/null || true
    ${pkgs.kmod}/bin/modprobe -r iwlwifi 2>/dev/null || true
    echo 1 > "$PCI_DEV/reset"
    ${pkgs.coreutils}/bin/sleep 1
    ${pkgs.kmod}/bin/modprobe iwlwifi
  '';
in
{
  boot.kernelModules = [ "iwlwifi" ];

  systemd.services.iwlwifi-reset = {
    description = "Reset Intel Wi-Fi PCI device (0000:02:00.0) if iwlwifi probe failed";
    after = [
      "systemd-udev-trigger.service"
      "systemd-modules-load.service"
    ];
    before = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${iwlwifiResetScript}";
    };
  };

  powerManagement.resumeCommands = ''
    ${iwlwifiResetScript}
  '';
}
