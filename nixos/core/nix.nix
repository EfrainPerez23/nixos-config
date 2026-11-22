# Nix daemon settings, Flakes, unfree packages, nix-ld, and `nh` (Nix Helper)

{ config, ... }:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  # Include ~/.local/bin in PATH
  environment.localBinInPath = true;

  programs = {
    # System-wide Git (required by Flakes and root operations)
    git.enable = true;

    # Support dynamically linked binaries
    nix-ld.enable = true;

    # nh (Nix Helper): clean rebuild diffs and automatic garbage collection
    nh = {
      enable = true;
      flake = config.my.user.flakeDir;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
    };
  };
}
