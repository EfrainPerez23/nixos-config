# XWayland wrapper for Guake with custom guake-toggle detecting the active pointer monitor via D-Bus

{
  lib,
  symlinkJoin,
  guake,
  makeWrapper,
  glib,
  gobject-introspection,
  gdk-pixbuf,
  pango,
  harfbuzz,
  at-spi2-core,
  gtk3,
}:

symlinkJoin {
  name = "guake-x11";
  paths = [ guake ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/guake \
      --set GDK_BACKEND x11 \
      --set GTK_THEME Adwaita:dark
    rm $out/bin/guake-toggle
    head -n 3 ${guake}/bin/..guake-toggle-wrapped-wrapped > $out/bin/guake-toggle
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
