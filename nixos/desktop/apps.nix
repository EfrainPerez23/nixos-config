# System-level desktop applications (browsers and IDEs)

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps;
  useVaapiFlags = builtins.elem config.my.hardware.gpu [
    "intel"
    "amd"
  ];
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.browsers.enable {
      programs.firefox.enable = true;

      environment.systemPackages = [
        (pkgs.google-chrome.override {
          commandLineArgs =
            if useVaapiFlags then
              [
                "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL"
                "--ignore-gpu-blocklist"
                "--enable-gpu-rasterization"
                "--enable-zero-copy"
              ]
            else
              [
                "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
                "--enable-gpu-rasterization"
              ];
        })
      ];
    })

    (lib.mkIf cfg.antigravity.enable {
      environment.systemPackages = [
        pkgs.antigravity-ide.fhs
      ];
    })
  ];
}
