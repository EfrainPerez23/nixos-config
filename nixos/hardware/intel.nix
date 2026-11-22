# Intel GPU profile: hardware acceleration for VA-API / OpenGL / Vulkan (iHD + i965 fallback)

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.my.hardware.gpu == "intel") {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # Modern VA-API driver (iHD)
        intel-vaapi-driver # Classic VA-API driver (i965 fallback for Intel 6th Gen / Skylake)
        libvdpau-va-gl
      ];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    environment.systemPackages = with pkgs; [
      libva-utils
    ];
  };
}
