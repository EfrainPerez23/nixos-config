# Custom Catppuccin Mocha GRUB theme with dual-boot logo

{
  runCommand,
  catppuccin-grub,
  gnused,
}:

runCommand "catppuccin-grub-custom" { } ''
  mkdir -p "$out"
  cp -r ${catppuccin-grub}/* "$out/"
  chmod -R u+w "$out"
  cp ${../../assets/grub-logo.png} "$out/logo.png"
  ${gnused}/bin/sed -i \
    -e 's|left = 50%-50|left = 50%-80|' \
    -e 's|top = 50%-50|top = 50%-130|' \
    "$out/theme.txt"
''
