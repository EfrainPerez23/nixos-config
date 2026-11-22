# System fonts (Nerd Font for terminal/CLI; preserves default GNOME UI fonts)

{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
