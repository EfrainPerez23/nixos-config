{
  description = "Modular NixOS + Home Manager configuration (GNOME Catppuccin Mocha)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Bootvine: live systemd dependency tree on boot/shutdown (via git+https to avoid Codeberg archive timeouts)
    bootvine = {
      url = "git+https://codeberg.org/wvhulle/bootvine.git";
      flake = false;
    };

    # Personal settings (username, full name, hostname, timezone).
    # Points to `local/example` publicly on GitHub; overridden locally via `--override-input local path:./local`.
    local = {
      url = "path:./local/example";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Helper to assemble each host profile cleanly and consistently
      mkHost =
        hostProfile: hostDir:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs hostProfile; };
          modules = [
            { nixpkgs.overlays = [ self.overlays.default ]; }
            ./nixos/core
            ./nixos/hardware
            ./nixos/desktop
            hostDir
            home-manager.nixosModules.home-manager
            (
              { config, ... }:
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = { inherit inputs hostProfile; };
                  users.${config.my.user.name} = import ./home;
                };
              }
            )
          ];
        };
    in
    {
      # Custom overlay (exposes pkgs.custom.*)
      overlays.default = import ./overlays;

      # Custom packages buildable directly via `nix build .#<pkg>`
      packages.${system} = import ./pkgs { inherit pkgs; };

      # Official Nix RFC-166 formatter (`nix fmt`)
      formatter.${system} = pkgs.nixfmt-tree;

      # Reproducible devShell (`nix develop` or automatically via `direnv allow`)
      devShells.${system}.default = pkgs.mkShell {
        name = "nixos-config-dev";
        packages = with pkgs; [
          just # Modern task runner for the justfile
          nixfmt # Official RFC-166 Nix formatter
          nil # Nix Language Server (LSP) for IDE completions and diagnostics
          statix # Nix linter for best practices
          deadnix # Detects unused Nix bindings and imports
          shellcheck # Shell script linter (used on scripts/new-host.sh)
        ];
        shellHook = ''
          echo "❄️  NixOS Dev shell ready (just, nixfmt, nil, statix, deadnix, shellcheck)"
        '';
      };

      # Host profiles (personal identity is injected dynamically from `local/`)
      nixosConfigurations = {
        laptop = mkHost "laptop" ./hosts/laptop;
        # <new-hosts>
      };
    };
}
