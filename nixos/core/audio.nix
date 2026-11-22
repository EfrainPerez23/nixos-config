# Modern audio stack with PipeWire + rtkit

{ pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pulseaudio # Provides `pactl` for per-app output switching in Quick Settings Audio Panel
  ];
}
