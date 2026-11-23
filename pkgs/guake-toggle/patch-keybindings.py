import sys

path = sys.argv[1]
with open(path, "r") as f:
    src = f.read()

old_block = (
    "            if key > 0:\n"
    "                self._lookup[mask][key] = action\n"
    "                self._masks |= mask"
)
new_block = (
    "            if key > 0:\n"
    "                self._lookup[mask][key] = action\n"
    "                self._masks |= mask\n"
    "                if key == Gdk.KEY_plus and mask == Gdk.ModifierType.CONTROL_MASK:\n"
    "                    self._lookup[mask][Gdk.KEY_equal] = action\n"
    "                    self._lookup[mask][Gdk.KEY_KP_Add] = action\n"
    "                    self._lookup[mask | Gdk.ModifierType.SHIFT_MASK][Gdk.KEY_plus] = action\n"
    "                    self._masks |= Gdk.ModifierType.SHIFT_MASK\n"
    "                elif key == Gdk.KEY_minus and mask == Gdk.ModifierType.CONTROL_MASK:\n"
    "                    self._lookup[mask][Gdk.KEY_KP_Subtract] = action"
)

assert old_block in src, "load_accelerators block not found in guake/keybindings.py"
with open(path, "w") as f:
    f.write(src.replace(old_block, new_block, 1))
