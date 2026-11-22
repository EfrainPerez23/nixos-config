import json, os, sys, time
os.environ.pop("GDK_BACKEND", None)
import dbus

def get_pointer_monitor(bus):
    try:
        shell = bus.get_object("org.gnome.Shell", "/org/gnome/Shell/Extensions/GuakeHelper")
        iface = dbus.Interface(shell, "org.gnome.Shell.Extensions.GuakeHelper")
        return json.loads(str(iface.GetPointerMonitor())), iface
    except Exception:
        return None, None

def compute_target_rect(mon, settings):
    wx = int(mon["workX"])
    wy = int(mon["workY"])
    ww = int(mon["workWidth"])
    wh = int(mon["workHeight"])

    height_pct = settings.get_int("window-height")
    width_pct = settings.get_int("window-width")
    halign = settings.get_int("window-halignment")
    valign = settings.get_int("window-valignment")
    vdisp = settings.get_int("window-vertical-displacement")
    hdisp = settings.get_int("window-horizontal-displacement")

    if halign == 0:  # ALIGN_CENTER
        w = int(ww * width_pct / 100.0)
        x = wx + (ww - w) // 2
    elif halign == 1:  # ALIGN_LEFT
        w = int((ww - hdisp) * width_pct / 100.0)
        x = wx + hdisp
    else:  # ALIGN_RIGHT
        w = int((ww - hdisp) * width_pct / 100.0)
        x = wx + ww - w - hdisp

    h = int(wh * height_pct / 100.0)
    if valign == 0:  # ALIGN_TOP
        y = wy + vdisp
    else:  # ALIGN_BOTTOM
        y = wy + wh - h - vdisp

    return x, y, max(w, 200), max(h, 100)

def map_point_to_x11_monitor(cx, cy, old_idx, Gdk):
    Gdk.set_allowed_backends("x11")
    x11_display = Gdk.Display.open(os.environ.get("DISPLAY", ":0"))
    if x11_display is None:
        return old_idx
    x11_mon = x11_display.get_monitor_at_point(cx, cy)
    for i in range(x11_display.get_n_monitors()):
        if x11_display.get_monitor(i) == x11_mon:
            return i
    return old_idx

def fallback_focused_point(bus):
    try:
        win_obj = bus.get_object("org.gnome.Shell", "/org/gnome/Shell/Extensions/Windows")
        win_iface = dbus.Interface(win_obj, "org.gnome.Shell.Extensions.Windows")
        info = json.loads(str(win_iface.GetFocusedWindowSync()))
        if info and "x" in info and "width" in info:
            return int(info["x"]) + int(info["width"]) // 2, int(info["y"]) + int(info["height"]) // 2
    except Exception:
        pass
    return None

try:
    bus = dbus.SessionBus()
    remote = bus.get_object("org.guake3.RemoteControl", "/org/guake3/RemoteControl")
    vis = int(remote.get_visibility())

    if vis == 1:
        remote.hide()
        sys.exit(0)

    import gi
    gi.require_version("Gdk", "3.0")
    gi.require_version("GdkX11", "3.0")
    from gi.repository import Gdk, GdkX11, Gio
    from guake.paths import SCHEMA_DIR

    schema_source = Gio.SettingsSchemaSource.new_from_directory(
        SCHEMA_DIR, Gio.SettingsSchemaSource.get_default(), False
    )
    settings = Gio.Settings.new_full(
        schema_source.lookup("guake.general", False), None, None
    )
    old_idx = settings.get_int("display-n")
    old_mouse = settings.get_boolean("mouse-display")

    mon, helper_iface = get_pointer_monitor(bus)
    idx = old_idx

    if mon is not None:
        cx = int(mon["x"]) + int(mon["width"]) // 2
        cy = int(mon["y"]) + int(mon["height"]) // 2
        idx = map_point_to_x11_monitor(cx, cy, old_idx, Gdk)
    else:
        pt = fallback_focused_point(bus)
        if pt is not None:
            idx = map_point_to_x11_monitor(pt[0], pt[1], old_idx, Gdk)

    changed = False
    if old_mouse:
        settings.set_boolean("mouse-display", False)
        changed = True
    if old_idx != idx:
        settings.set_int("display-n", idx)
        changed = True
    if changed:
        Gio.Settings.sync()
        time.sleep(0.03)

    if mon is not None and helper_iface is not None:
        tx, ty, tw, th = compute_target_rect(mon, settings)
        try:
            helper_iface.ArmPlacement(tx, ty, tw, th)
        except Exception:
            pass

    remote.show()
except dbus.DBusException:
    os.execvp("guake", ["guake"])
