# Vicinae launcher: user systemd daemon and mutable initial settings.json seeding

{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  config = lib.mkIf osConfig.my.desktop.vicinae.enable {
    systemd.user.services.vicinae = {
      Unit = {
        Description = "Vicinae Launcher Daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.vicinae}/bin/vicinae server --replace";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "process";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Seed ~/.config/vicinae/settings.json only if missing (remains editable via the GUI)
    home.activation.vicinaeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="$HOME/.config/vicinae/settings.json"
      if [ ! -f "$target" ]; then
        run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/vicinae"
        run ${pkgs.coreutils}/bin/install -m 644 "${./vicinae.json}" "$target"
      fi
    '';

    # Restart Vicinae after every switch so newly installed NixOS apps are re-indexed
    home.activation.vicinaeRefresh = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      if [ -z "''${DRY_RUN:-}" ]; then
        ${pkgs.systemd}/bin/systemctl --user try-restart vicinae.service || true
      fi
    '';
  };
}
