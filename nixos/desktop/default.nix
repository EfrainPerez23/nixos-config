# Optional desktop and application modules (toggled per host in `hosts/<profile>/default.nix`)

{ ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./apps.nix
  ];
}
