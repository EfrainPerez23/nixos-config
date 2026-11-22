# Minimal GNOME Shell extension exposing the real pointer monitor (global.get_pointer)
# and reliably positioning/resizing Guake directly via Mutter when mapped.

{ runCommand }:

runCommand "gnome-shell-extension-guake-helper" { } ''
  extDir="$out/share/gnome-shell/extensions/guake-helper@local"
  mkdir -p "$extDir"
  cp ${./metadata.json} "$extDir/metadata.json"
  cp ${./extension.js} "$extDir/extension.js"
''
