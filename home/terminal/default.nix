# Terminal configuration: Fish, Starship, and CLI tools

{ ... }:

{
  imports = [
    ./fish.nix
    ./starship.nix
    ./cli.nix
  ];
}
