# Catppuccin Mocha Purple Colloid GTK + GNOME Shell theme with custom
# Accent Stripe (SwayNC-inspired) styling for top-right notification banners.

{ colloid-gtk-theme }:

let
  base = colloid-gtk-theme.override {
    themeVariants = [ "purple" ];
    colorVariants = [ "dark" ];
    tweaks = [
      "catppuccin"
      "rimless"
      "float"
      "normal"
    ];
  };
in
base.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    shellCss="$out/share/themes/Colloid-Purple-Dark-Catppuccin/gnome-shell/gnome-shell.css"
    test -f "$shellCss"
    printf '\n' >> "$shellCss"
    cat ${./notifications.css} >> "$shellCss"
  '';
})
