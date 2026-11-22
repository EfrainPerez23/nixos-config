# NVIDIA GPU profile (RTX 2000/3000/4000/5000): official driver with Wayland and VA-API support
# Note: for hybrid laptops (Intel/AMD + RTX), add `hardware.nvidia.prime` in `hosts/<profile>/default.nix`.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.my.hardware.gpu == "nvidia") {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = config.my.hardware.nvidiaOpen;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}
