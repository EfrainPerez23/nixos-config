# Home Manager entry point (user environment, dotfiles, and desktop settings)

{ osConfig, ... }:

let
  username = osConfig.my.user.name;
in
{
  imports = [
    ./desktop
    ./terminal
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    # Initial Home Manager state version (do not change after installation)
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
