# XWayland wrapper for Guake with custom guake-toggle detecting the active pointer monitor via D-Bus

{
  lib,
  symlinkJoin,
  guake,
  makeWrapper,
  python3,
  glib,
  gobject-introspection,
  gdk-pixbuf,
  pango,
  harfbuzz,
  at-spi2-core,
  gtk3,
}:

let
  # Alias Ctrl++ to also match Ctrl+= (US layout), Ctrl+Shift++ (US shifted), and Ctrl+KP_Add,
  # and alias Ctrl+- to also match Ctrl+KP_Subtract, so split shortcuts work on both US and LatAm layouts.
  patchedGuake = guake.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      ${python3}/bin/python3 ${./patch-keybindings.py} guake/keybindings.py
    '';
  });
in
symlinkJoin {
  name = "guake-x11";
  paths = [ patchedGuake ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/guake \
      --set GDK_BACKEND x11 \
      --set GTK_THEME Adwaita:dark
    rm $out/bin/guake-toggle
    head -n 3 ${patchedGuake}/bin/..guake-toggle-wrapped-wrapped > $out/bin/guake-toggle
    cat ${./guake-toggle.py} >> $out/bin/guake-toggle
    chmod +x $out/bin/guake-toggle
    wrapProgram $out/bin/guake-toggle \
      --set GI_TYPELIB_PATH "${
        lib.makeSearchPath "lib/girepository-1.0" [
          glib.out
          gobject-introspection
          gdk-pixbuf
          pango.out
          harfbuzz
          at-spi2-core
          gtk3
        ]
      }"
  '';
}
