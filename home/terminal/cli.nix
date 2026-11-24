# Declarative CLI tools (btop, bat, fastfetch, cava, eza, git, direnv) + Antigravity CLI bootstrap

{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  # Official Catppuccin Mocha themes for btop and bat
  catppuccinMochaThemes = pkgs.catppuccin.override {
    variant = "mocha";
    accent = "mauve";
    themeList = [
      "btop"
      "bat"
    ];
  };
in
{
  home.packages = with pkgs; [
    curl
    wget
    eza
    fastfetch
    cava

    # Nix development tooling (available to both terminal and IDE)
    just
    gnumake
    nixfmt
    nil
    statix
    deadnix

    # Python development tooling
    uv
  ];

  programs = {
    # direnv + nix-direnv: automatically loads flake devShells per project
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # btop with Catppuccin Mocha theme and transparent background (great for Guake)
    btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_mocha";
        theme_background = false;
        truecolor = true;
        rounded_corners = true;
      };
    };

    # bat with Catppuccin Mocha theme (Home Manager builds the theme cache automatically)
    bat = {
      enable = true;
      config = {
        theme = "Catppuccin Mocha";
        style = "numbers,changes,header";
      };
      themes."Catppuccin Mocha" = {
        src = catppuccinMochaThemes;
        file = "bat/Catppuccin Mocha.tmTheme";
      };
    };
  };

  # Declarative themes and configs (btop, fastfetch, cava)
  xdg.configFile = {
    "btop/themes/catppuccin_mocha.theme".source =
      "${catppuccinMochaThemes}/btop/catppuccin_mocha.theme";
    "fastfetch/config.jsonc".source = ./configs/fastfetch.jsonc;
    "cava/config".source = ./configs/cava.conf;
  };

  # Install Antigravity CLI into ~/.local/bin/agy if enabled and not yet present
  home.activation.antigravityCli = lib.mkIf osConfig.my.apps.antigravity.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -z "''${DRY_RUN:-}" ] && [ ! -x "$HOME/.local/bin/agy" ]; then
        export PATH="${
          lib.makeBinPath [
            pkgs.curl
            pkgs.bash
            pkgs.coreutils
            pkgs.gnutar
            pkgs.gzip
          ]
        }:$PATH"
        ${pkgs.curl}/bin/curl -fsSL https://antigravity.google/cli/install.sh | ${pkgs.bash}/bin/bash || true
      fi
    ''
  );
}
