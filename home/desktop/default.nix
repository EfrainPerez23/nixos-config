# User-level desktop configuration (GNOME, Guake, and Vicinae)

{ ... }:

{
  imports = [
    ./gnome
    ./guake.nix
    ./vicinae.nix
  ];
}
