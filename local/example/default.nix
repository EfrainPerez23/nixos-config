# Public template for personal and regional settings (no real personal data on GitHub).
# On your machine, create `local/local.nix` (gitignored) by copying this file
# or running `./scripts/new-host.sh`:
#   cp local/example/default.nix local/local.nix

{
  hostName = "nixos";
  username = "myuser";
  fullName = "NixOS User";
  flakeDir = "/home/myuser/Projects/nixos-config";
  timeZone = "UTC";
  defaultLocale = "en_US.UTF-8";
  extraLocale = "en_US.UTF-8";
  xkbLayout = "us";
  xkbVariant = "";
}
