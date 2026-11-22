# Dynamically loads personal and regional settings from `inputs.local`
# - Public GitHub default uses `local/example/default.nix` (generic placeholders)
# - Locally overridden with `--override-input local path:./local` to load `local/local.nix` (gitignored)

{ inputs, lib, ... }:

let
  local =
    if builtins.pathExists "${inputs.local}/local.nix" then
      import "${inputs.local}/local.nix"
    else
      import "${inputs.local}/default.nix";
in
{
  networking.hostName = lib.mkDefault local.hostName;

  my = {
    user = {
      name = lib.mkDefault local.username;
      fullName = lib.mkDefault local.fullName;
      flakeDir = lib.mkDefault local.flakeDir;
    };

    locale = {
      timeZone = lib.mkDefault local.timeZone;
      defaultLocale = lib.mkDefault local.defaultLocale;
      extraLocale = lib.mkDefault local.extraLocale;
      xkbLayout = lib.mkDefault local.xkbLayout;
      xkbVariant = lib.mkDefault local.xkbVariant;
    };
  };
}
