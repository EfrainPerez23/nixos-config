# Global GNOME keybindings (Guake, Vicinae, Gradia, volume, and per-window Alt+Tab)

{ lib, osConfig, ... }:

{
  config = lib.mkIf osConfig.my.desktop.gnome.enable {
    dconf.settings = with lib.hm.gvariant; {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        ];
        volume-up = [ "<Control><Alt>Up" ];
        volume-down = [ "<Control><Alt>Down" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Control>grave";
        command = "guake-toggle";
        name = "Toggle guake terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>f";
        command = "vicinae toggle";
        name = "Toggle Vicinae";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "Print";
        command = "gradia --screenshot=INTERACTIVE";
        name = "Gradia Screenshot";
      };

      # Unbind Print from GNOME's built-in screenshot UI so Gradia can handle it
      "org/gnome/shell/keybindings" = {
        show-screenshot-ui = mkEmptyArray type.string;
      };

      # Free Ctrl+Alt+Up/Down for volume controls and switch individual windows with Alt+Tab
      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-up = mkEmptyArray type.string;
        switch-to-workspace-down = mkEmptyArray type.string;
        switch-applications = [ "<Super>Tab" ];
        switch-applications-backward = [ "<Shift><Super>Tab" ];
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
      };
    };
  };
}
