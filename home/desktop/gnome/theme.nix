# Global GNOME appearance: Catppuccin Mocha + Mauve (preserving native GNOME UI fonts)

{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  colloidCatppuccinTheme = pkgs.colloid-gtk-theme.override {
    themeVariants = [ "purple" ];
    colorVariants = [ "dark" ];
    tweaks = [
      "catppuccin"
      "rimless"
      "float"
      "normal"
    ];
  };
  themeDir = "${colloidCatppuccinTheme}/share/themes/Colloid-Purple-Dark-Catppuccin";
in
{
  config = lib.mkIf osConfig.my.desktop.gnome.enable {
    # Link Colloid Catppuccin into ~/.config/gtk-4.0 so native GNOME GTK4 / Libadwaita apps
    # (Settings, Files/Nautilus, Tweaks, Extension Manager, etc.) also use Catppuccin instead of stock Adwaita.
    xdg.configFile = {
      "gtk-4.0/assets" = {
        source = "${themeDir}/gtk-4.0/assets";
        force = true;
      };
      "gtk-4.0/gtk.css" = {
        source = "${themeDir}/gtk-4.0/gtk.css";
        force = true;
      };
      "gtk-4.0/gtk-dark.css" = {
        source = "${themeDir}/gtk-4.0/gtk-dark.css";
        force = true;
      };
    };

    dconf.settings = with lib.hm.gvariant; {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        accent-color = "purple";
        gtk-theme = "Colloid-Purple-Dark-Catppuccin";
        icon-theme = "Papirus-Dark";
        cursor-theme = "catppuccin-mocha-mauve-cursors";
        cursor-size = mkInt32 24;
        enable-hot-corners = false;
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "Colloid-Purple-Dark-Catppuccin";
      };

      # Center newly opened windows (recommended for Vicinae on GNOME Wayland)
      "org/gnome/mutter" = {
        center-new-windows = true;
      };
    };
  };
}
