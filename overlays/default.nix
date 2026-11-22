# Exposes all custom packages and patches from ./pkgs under `pkgs.custom.*`

_final: prev: {
  custom = import ../pkgs { pkgs = prev; };
}
