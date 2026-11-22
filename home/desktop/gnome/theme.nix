# Global GNOME appearance: Catppuccin Mocha + Mauve (preserving native GNOME UI fonts)

{ lib, osConfig, ... }:

{
  config = lib.mkIf osConfig.my.desktop.gnome.enable {
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
