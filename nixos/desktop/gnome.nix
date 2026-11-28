# System-level GNOME setup: GDM, Wayland session variables, GTK/icon/cursor themes, and extension packages
# (User-level GNOME appearance, shortcuts, and dconf settings live under `home/desktop/gnome/`)

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop;

  # Papirus Dark icons with Catppuccin Mocha Mauve folders
  papirusCatppuccinIcons = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "mauve";
  };
in
{
  config = lib.mkIf cfg.gnome.enable {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
    programs.dconf.enable = true;

    # Native Wayland hints and Catppuccin Mocha Mauve cursor
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XCURSOR_THEME = "catppuccin-mocha-mauve-cursors";
      XCURSOR_SIZE = "24";
    };

    environment.systemPackages =
      (with pkgs; [
        # Themes, icons, and cursors
        custom.colloid-catppuccin-theme
        papirusCatppuccinIcons
        catppuccin-cursors.mochaMauve
        gnome-themes-extra

        # GNOME desktop utilities
        gnome-tweaks
        gnome-extension-manager

        # GNOME Shell extensions
        gnomeExtensions.dash-to-panel
        gnomeExtensions.user-themes
        gnomeExtensions.blur-my-shell
        gnomeExtensions.space-bar
        gnomeExtensions.burn-my-windows
        gnomeExtensions.vitals
        gnomeExtensions.compiz-alike-magic-lamp-effect
        gnomeExtensions.just-perfection

        # Custom patched extensions (via `pkgs.custom` overlay)
        custom.azclock-multimonitor
        custom.coverflow-alt-tab
        custom.dynamic-music-pill
        custom.quick-settings-audio-panel
        custom.rounded-window-corners
      ])
      ++ lib.optionals cfg.guake.enable [
        pkgs.custom.guake-toggle
        pkgs.custom.guake-helper
      ]
      ++ lib.optionals cfg.vicinae.enable [
        pkgs.vicinae
        pkgs.gnomeExtensions.vicinae
      ];
  };
}
