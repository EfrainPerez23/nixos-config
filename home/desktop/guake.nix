# User configuration for Guake (autostart and dconf with Catppuccin Mocha palette)

{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  # Official Catppuccin Mocha palette in Guake's 16-bit color format (16 ANSI + foreground + background)
  catppuccinMochaPalette = builtins.concatStringsSep ":" [
    "#454547475a5a"
    "#f3f38b8ba8a8"
    "#a6a6e3e3a1a1"
    "#f9f9e2e2afaf"
    "#8989b4b4fafa"
    "#f5f5c2c2e7e7"
    "#9494e2e2d5d5"
    "#babac2c2dede"
    "#58585b5b7070"
    "#f3f38b8ba8a8"
    "#a6a6e3e3a1a1"
    "#f9f9e2e2afaf"
    "#8989b4b4fafa"
    "#f5f5c2c2e7e7"
    "#9494e2e2d5d5"
    "#a6a6adadc8c8"
    "#cdcdd6d6f4f4"
    "#1e1e1e1e2e2e"
  ];
in
{
  config = lib.mkIf osConfig.my.desktop.guake.enable {
    # Autostart Guake when the graphical session starts.
    # Use a distinct filename from `guake.desktop` and keep `start-at-login = false`
    # because Guake's `refresh_user_start()` tries to overwrite/remove
    # `~/.config/autostart/guake.desktop`, which crashes with EROFS on a Home Manager symlink.
    xdg.configFile."autostart/guake-autostart.desktop".source =
      "${pkgs.custom.guake-toggle}/share/guake/autostart-guake.desktop";

    dconf.settings = with lib.hm.gvariant; {
      "org/guake/general" = {
        compat-delete = "delete-sequence";
        default-shell = "/run/current-system/sw/bin/fish";
        display-n = mkInt32 0;
        display-tab-names = mkInt32 0;
        gtk-prefer-dark-theme = true;
        gtk-theme-name = "Adwaita";
        gtk-use-system-default-theme = false;
        hide-tabs-if-one-tab = false;
        history-size = mkInt32 1000;
        load-guake-yml = true;
        max-tab-name-length = mkInt32 100;
        mouse-display = false;
        open-tab-cwd = true;
        prompt-on-quit = true;
        quick-open-command-line = "gedit %(file_path)s";
        restore-tabs-notify = true;
        restore-tabs-startup = true;
        save-tabs-when-changed = true;
        schema-version = "3.10.1";
        scroll-keystroke = true;
        start-at-login = false;
        use-audible-bell = false;
        use-default-font = false;
        use-popup = true;
        use-scrollbar = true;
        use-trayicon = true;
        window-halignment = mkInt32 0;
        window-height = mkInt32 50;
        window-losefocus = false;
        window-refocus = false;
        window-tabbar = true;
        window-width = mkInt32 100;
      };

      # Disable Guake's internal X11 shortcut to avoid conflicts with GNOME Wayland keybindings
      "org/guake/keybindings/global" = {
        show-hide = "disabled";
      };

      # Local terminal shortcuts: Ctrl++ vertical split, Ctrl+- horizontal split, Ctrl+D close pane
      "org/guake/keybindings/local" = {
        split-tab-vertical = "<Control>plus";
        split-tab-horizontal = "<Control>minus";
        close-terminal = "<Control>d";
        # Free Ctrl++ / Ctrl+= / Ctrl+- from zoom so splits work cleanly
        zoom-in = "";
        zoom-in-alt = "";
        zoom-out = "";
      };

      "org/guake/style" = {
        cursor-blink-mode = mkInt32 1;
        cursor-shape = mkInt32 1;
      };

      "org/guake/style/background" = {
        transparency = mkInt32 90;
      };

      "org/guake/style/font" = {
        allow-bold = true;
        style = "JetBrainsMono Nerd Font 11";
        palette = catppuccinMochaPalette;
        palette-name = "Catppuccin Mocha";
      };
    };
  };
}
