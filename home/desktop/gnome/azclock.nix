# Multi-monitor desktop clocks (Desktop Clock / azclock) styled in Catppuccin Mocha + Mauve

{ lib, osConfig, ... }:

let
  widgets = [
    {
      monitor = 0;
      id = "5044819d-15a8-44f5-b5e2-1f2d7fbc5bc7";
      timeId = "064dddfd-f914-40d9-ac40-6c6f918c5a80";
      dateId = "d031dd13-d1c9-422e-8b11-8df463bd759d";
    }
    {
      monitor = 1;
      id = "5044819d-15a8-44f5-b5e2-1f2d7fbc5bc1";
      timeId = "064dddfd-f914-40d9-ac40-6c6f918c5a81";
      dateId = "d031dd13-d1c9-422e-8b11-8df463bd7591";
    }
    {
      monitor = 2;
      id = "5044819d-15a8-44f5-b5e2-1f2d7fbc5bc2";
      timeId = "064dddfd-f914-40d9-ac40-6c6f918c5a82";
      dateId = "d031dd13-d1c9-422e-8b11-8df463bd7592";
    }
    {
      monitor = 3;
      id = "5044819d-15a8-44f5-b5e2-1f2d7fbc5bc3";
      timeId = "064dddfd-f914-40d9-ac40-6c6f918c5a83";
      dateId = "d031dd13-d1c9-422e-8b11-8df463bd7593";
    }
  ];

  azClockSettings =
    with lib.hm.gvariant;
    let
      enabledEntry = id: [
        (mkDictionaryEntry [
          id
          (mkVariant [
            (mkDictionaryEntry [
              "enabled"
              (mkVariant true)
            ])
          ])
        ])
      ];
    in
    lib.mergeAttrsList (
      [
        {
          "org/gnome/shell/extensions/azclock" = {
            create-initial-widget = false;
            widgets = map (w: enabledEntry w.id) widgets;
          };
        }
      ]
      ++ map (w: {
        "org/gnome/shell/extensions/azclock/widget-data/${w.id}" = {
          convert-old-location-done = true;
          elements = [
            (enabledEntry w.timeId)
            (enabledEntry w.dateId)
          ];
          location-data = builtins.toJSON {
            monitorIndex = w.monitor;
            relativeX = 0.01953125;
            relativeY = 0.034722222222222224;
          };
          name = "Digital Clock Widget";
          show-background = false;
          show-border = false;
          spacing = mkInt32 4;
        };

        "org/gnome/shell/extensions/azclock/widget-data/${w.id}/element-data/${w.timeId}" = {
          name = "Time Label";
          date-format = "%H:%M";
          font-size = mkInt32 68;
          font-weight = mkInt32 700;
          foreground-color = "#cdd6f4";
          shadow = mkTuple [
            true
            "rgba(17, 17, 27, 0.7)"
            (mkInt32 0)
            (mkInt32 3)
            (mkInt32 0)
            (mkInt32 10)
          ];
        };

        "org/gnome/shell/extensions/azclock/widget-data/${w.id}/element-data/${w.dateId}" = {
          name = "Date Label";
          date-format = "%A, %d %b";
          font-size = mkInt32 20;
          font-weight = mkInt32 500;
          foreground-color = "#cba6f7";
          shadow = mkTuple [
            true
            "rgba(17, 17, 27, 0.7)"
            (mkInt32 0)
            (mkInt32 2)
            (mkInt32 0)
            (mkInt32 8)
          ];
        };
      }) widgets
    );
in
{
  config = lib.mkIf osConfig.my.desktop.gnome.enable {
    dconf.settings = azClockSettings;
  };
}
