# Declarative GNOME settings (split by area for quick navigation)

{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.my.desktop;
in
{
  imports = [
    ./theme.nix
    ./keybindings.nix
    ./panel.nix
    ./effects.nix
    ./azclock.nix
  ];

  config = lib.mkIf cfg.gnome.enable {
    # Ensure Home Manager's dconf activation talks to the live user D-Bus session
    # instead of spawning an isolated `dbus-run-session` when `just apply` runs.
    home.activation.ensureLiveDbusSession = lib.hm.dag.entryBefore [ "dconfSettings" ] ''
      uid="$(${pkgs.coreutils}/bin/id -u)"
      if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/$uid/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus"
      fi
    '';

    dconf.settings."org/gnome/shell" = with lib.hm.gvariant; {
      disable-user-extensions = false;
      disabled-extensions = mkEmptyArray type.string;
      enabled-extensions = [
        "dash-to-panel@jderose9.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "blur-my-shell@aunetx"
        "rounded-window-corners@fxgn"
        "space-bar@luchrioh"
        "azclock@azclock.gitlab.com"
        "burn-my-windows@schneegans.github.com"
        "CoverflowAltTab@palatis.blogspot.com"
        "Vitals@CoreCoding.com"
        "quick-settings-audio-panel@rayzeq.github.io"
        "compiz-alike-magic-lamp-effect@hermes83.github.com"
        "just-perfection-desktop@just-perfection"
        "dynamic-music-pill@andbal"
      ]
      ++ lib.optional cfg.guake.enable "guake-helper@local"
      ++ lib.optional cfg.vicinae.enable "vicinae@dagimg-dot";
    };
  };
}
