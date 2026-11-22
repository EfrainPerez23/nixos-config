# AMD GPU profile (Radeon / Ryzen iGPU): open-source amdgpu + Mesa / Vulkan / VA-API

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.my.hardware.gpu == "amd") {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      libva-utils
    ];
  };
}
