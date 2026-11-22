# GNOME visual effects and animations:
# Blur my Shell, Rounded Window Corners, Coverflow Alt-Tab, Burn My Windows, Magic Lamp, and Just Perfection

{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  config = lib.mkIf osConfig.my.desktop.gnome.enable {
    dconf.settings = with lib.hm.gvariant; {
      # Blur my Shell tuned for Intel HD 520 (smooth frosted glass without hurting IDE FPS)
      "org/gnome/shell/extensions/blur-my-shell" = {
        sigma = mkInt32 24;
        brightness = 0.65;
      };
      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        blur = true;
        static-blur = true;
        override-background = false;
        unblur-in-overview = true;
      };
      "org/gnome/shell/extensions/blur-my-shell/dash-to-panel" = {
        blur-original-panel = true;
      };
      "org/gnome/shell/extensions/blur-my-shell/overview" = {
        blur = true;
        style-components = mkInt32 2;
      };
      "org/gnome/shell/extensions/blur-my-shell/applications" = {
        blur = false;
      };

      # Rounded window corners with subtle Catppuccin Mauve border (excluding Guake)
      "org/gnome/shell/extensions/rounded-window-corners-reborn" = {
        skip-libadwaita-app = false;
        border-width = mkInt32 1;
        blacklist = [
          "guake"
          "Guake"
        ];
        global-rounded-corner-settings = [
          (mkDictionaryEntry [
            "padding"
            (mkVariant [
              (mkDictionaryEntry [
                "left"
                (mkVariant (mkUint32 1))
              ])
              (mkDictionaryEntry [
                "right"
                (mkVariant (mkUint32 1))
              ])
              (mkDictionaryEntry [
                "top"
                (mkVariant (mkUint32 1))
              ])
              (mkDictionaryEntry [
                "bottom"
                (mkVariant (mkUint32 1))
              ])
            ])
          ])
          (mkDictionaryEntry [
            "keepRoundedCorners"
            (mkVariant [
              (mkDictionaryEntry [
                "maximized"
                (mkVariant false)
              ])
              (mkDictionaryEntry [
                "fullscreen"
                (mkVariant false)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "borderRadius"
            (mkVariant (mkUint32 14))
          ])
          (mkDictionaryEntry [
            "smoothing"
            (mkVariant 0.2)
          ])
          (mkDictionaryEntry [
            "borderColor"
            (mkVariant [
              0.796
              0.651
              0.969
              0.45
            ])
          ])
          (mkDictionaryEntry [
            "enabled"
            (mkVariant true)
          ])
        ];
      };

      # Burn My Windows without startup support dialog
      "org/gnome/shell/extensions/burn-my-windows" = {
        show-support-dialog = false;
      };

      # Coverflow Alt-Tab: 3D animated window switcher
      "org/gnome/shell/extensions/coverflowalttab" = {
        switcher-style = "Coverflow";
        animation-time = 0.22;
        easing-function = "ease-out-cubic";
        dim-factor = 0.6;
        hide-panel = false;
        icon-style = "Classic";
        position = "Bottom";
        switch-application-behaves-like-switch-windows = true;
      };

      # Compiz Magic Lamp minimize animation
      "org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect" = {
        effect = "default";
        duration = 320.0;
      };

      # Just Perfection: snappy animations (0.8x) and shell polish
      "org/gnome/shell/extensions/just-perfection" = {
        animation = mkInt32 5;
        workspace-wrap-around = true;
        window-demands-attention-focus = true;
      };
    };

    # Seed the Burn My Windows glide profile if no profiles exist yet (remains GUI-editable)
    home.activation.burnMyWindowsProfile =
      let
        glideProfile = pkgs.writeText "showcase-glide.conf" ''
          [burn-my-windows-profile]
          fire-enable-effect=false
          glide-enable-effect=true
          glide-animation-time=220
          glide-scale=0.95
          glide-squish=0.0
          glide-tilt=0.0
          glide-shift=-0.05
        '';
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        profileDir="$HOME/.config/burn-my-windows/profiles"
        if [ ! -d "$profileDir" ] || [ -z "$(${pkgs.coreutils}/bin/ls -A "$profileDir" 2>/dev/null)" ]; then
          run ${pkgs.coreutils}/bin/mkdir -p "$profileDir"
          run ${pkgs.coreutils}/bin/install -m 644 "${glideProfile}" "$profileDir/showcase-glide.conf"
        fi
      '';
  };
}
