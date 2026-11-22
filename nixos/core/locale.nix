# Timezone, locales, and keyboard layout (driven by `my.locale`)

{ config, ... }:

let
  cfg = config.my.locale;
in
{
  time.timeZone = cfg.timeZone;

  i18n.defaultLocale = cfg.defaultLocale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = cfg.extraLocale;
    LC_IDENTIFICATION = cfg.extraLocale;
    LC_MEASUREMENT = cfg.extraLocale;
    LC_MONETARY = cfg.extraLocale;
    LC_NAME = cfg.extraLocale;
    LC_NUMERIC = cfg.extraLocale;
    LC_PAPER = cfg.extraLocale;
    LC_TELEPHONE = cfg.extraLocale;
    LC_TIME = cfg.extraLocale;
  };

  services.xserver.xkb = {
    layout = cfg.xkbLayout;
    variant = cfg.xkbVariant;
  };
}
