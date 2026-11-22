# Reusable GPU hardware profiles (selected via `my.hardware.gpu`)

{ ... }:

{
  imports = [
    ./intel.nix
    ./amd.nix
    ./nvidia.nix
  ];
}
