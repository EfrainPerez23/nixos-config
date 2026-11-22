# Primary user account (driven by `my.user`) and system-level Fish shell registration

{ config, pkgs, ... }:

let
  cfg = config.my.user;
in
{
  # Required at system level to use Fish as a login shell
  programs.fish.enable = true;

  users.users.${cfg.name} = {
    isNormalUser = true;
    description = cfg.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };
}
