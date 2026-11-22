# Core operating system modules (applied to all hosts)

{ ... }:

{
  imports = [
    ./options.nix
    ./local.nix
    ./nix.nix
    ./boot.nix
    ./locale.nix
    ./networking.nix
    ./audio.nix
    ./printing.nix
    ./users.nix
  ];
}
