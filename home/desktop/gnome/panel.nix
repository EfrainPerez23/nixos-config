# Top bar and panel widgets: Dash to Panel, Space Bar, Vitals, Dynamic Music Pill, and Audio Panel

{ lib, osConfig, ... }:

let
  # Clean top-bar layout for Dash to Panel (Space Bar on the left, clock and music centered)
  topBarElements = [
    {
      element = "activitiesButton";
      visible = false;
      position = "stackedTL";
    }
    {
      element = "leftBox";
      visible = true;
      position = "stackedTL";
    }
    {
      element = "showAppsButton";
      visible = false;
      position = "stackedTL";
    }
    {
      element = "taskbar";
      visible = false;
      position = "stackedTL";
    }
    {
      element = "centerBox";
      visible = true;
      position = "centerMonitor";
    }
    {
      element = "dateMenu";
      visible = true;
      position = "centerMonitor";
    }
    {
      element = "rightBox";
      visible = true;
      position = "stackedBR";
    }
    {
      element = "systemMenu";
      visible = true;
      position = "stackedBR";
    }
    {
      element = "desktopButton";
      visible = false;
      position = "stackedBR";
    }
  ];

  dashToPanelElementPositions = builtins.toJSON {
    "0" = topBarElements;
    "1" = topBarElements;
    "2" = topBarElements;
    "3" = topBarElements;
  };
in
{
  config = lib.mkIf osConfig.my.desktop.gnome.enable {
    dconf.settings = with lib.hm.gvariant; {
      # Dash to Panel: multi-monitor top bar with intellihide and Catppuccin Mocha glass tint
      "org/gnome/shell/extensions/dash-to-panel" = {
        multi-monitors = true;
        panel-position = "TOP";
        panel-positions = "{}";
        panel-size = mkInt32 32;
        panel-sizes = "{}";
        panel-lengths = "{}";
        panel-anchors = "{}";
        panel-element-positions-monitors-sync = true;
        panel-element-positions = dashToPanelElementPositions;
        stockgs-keep-dash = true;
        show-activities-button = false;
        intellihide = true;
        intellihide-hide-from-windows = false;
        intellihide-only-secondary = false;
        intellihide-use-pointer = true;
        intellihide-revealed-hover = true;
        intellihide-use-pressure = false;
        intellihide-animation-time = mkInt32 200;
        intellihide-close-delay = mkInt32 300;
        intellihide-reveal-delay = mkInt32 0;
        intellihide-show-in-fullscreen = false;
        trans-use-custom-bg = true;
        trans-bg-color = "#1e1e2e";
        trans-use-custom-opacity = true;
        trans-use-dynamic-opacity = false;
        trans-panel-opacity = 0.35;
      };

      # Space Bar: Catppuccin Mocha Mauve workspace pills
      "org/gnome/shell/extensions/space-bar/behavior" = {
        indicator-style = "workspaces-bar";
        position = "left";
        position-index = mkInt32 0;
        show-empty-workspaces = true;
        smart-workspace-names = false;
        toggle-overview = true;
      };

      "org/gnome/shell/extensions/space-bar/appearance" = {
        workspaces-bar-padding = mkInt32 8;
        workspace-margin = mkInt32 4;
        active-workspace-background-color = "rgba(203,166,247,0.92)";
        active-workspace-text-color = "rgba(30,30,46,1)";
        active-workspace-border-radius = mkInt32 8;
        active-workspace-padding-h = mkInt32 10;
        active-workspace-padding-v = mkInt32 2;
        inactive-workspace-background-color = "rgba(49,50,68,0.65)";
        inactive-workspace-text-color = "rgba(205,214,244,0.9)";
        inactive-workspace-text-color-active = true;
        inactive-workspace-border-radius = mkInt32 8;
        inactive-workspace-border-radius-active = true;
        empty-workspace-text-color = "rgba(166,173,200,0.5)";
      };

      # Vitals: compact CPU and RAM indicators
      "org/gnome/shell/extensions/vitals" = {
        hot-sensors = [
          "_processor_usage_"
          "_memory_usage_"
        ];
      };

      # Quick Settings Audio Panel: MPRIS controls + per-application volume sliders
      "org/gnome/shell/extensions/quick-settings-audio-panel" = {
        panel-type = "independent-panel";
        create-mpris-controllers = true;
        mpris-controllers-are-moved = true;
        create-applications-volume-sliders = true;
        master-volume-sliders-show-current-device = true;
        always-show-input-volume-slider = false;
      };

      # Dynamic Music Pill: centered player with real-time Cava visualizer across all monitors
      "org/gnome/shell/extensions/dynamic-music-pill" = {
        target-container = mkInt32 2; # Panel: Center Box
        position-mode = mkInt32 3; # Next to the clock
        panel-pill-height = mkInt32 26;
        panel-pill-width = mkInt32 240;
        pill-dynamic-width = true;
        panel-art-size = mkInt32 20;
        border-radius = mkInt32 14;
        visualizer-style = mkInt32 3; # Real-Time (Cava)
        visualizer-bars = mkInt32 8;
        visualizer-bar-width = mkInt32 2;
        visualizer-height = mkInt32 16;
        popup-show-visualizer = true;
        action-hover = "toggle_menu";
        hover-delay = mkInt32 250;
        popup-hide-on-leave = true;
        use-custom-colors = true;
        custom-bg-color = "30,30,46";
        custom-text-color = "205,214,244";
        enable-transparency = true;
        transparency-strength = mkInt32 75;
        hide-default-player = false;
        enable-gamemode = true;
      };
    };
  };
}
