import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const DBUS_IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.GuakeHelper">
    <method name="GetPointerMonitor">
      <arg type="s" direction="out" name="info"/>
    </method>
    <method name="ArmPlacement">
      <arg type="i" direction="in" name="x"/>
      <arg type="i" direction="in" name="y"/>
      <arg type="i" direction="in" name="width"/>
      <arg type="i" direction="in" name="height"/>
      <arg type="b" direction="out" name="ok"/>
    </method>
  </interface>
</node>`;

export default class GuakeHelperExtension extends Extension {
  enable() {
    this._pending = null;
    this._timers = new Set();

    this._mapSignalId = global.window_manager.connect('map', (_wm, actor) => {
      const win = actor?.meta_window;
      if (!win || !this._pending) return;
      if (GLib.get_monotonic_time() > this._pending.deadline) {
        this._pending = null;
        return;
      }
      if (!this._isGuake(win)) return;

      const rect = this._pending;
      this._schedulePlace(win, rect);
    });

    this._dbus = Gio.DBusExportedObject.wrapJSObject(DBUS_IFACE, this);
    this._dbus.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/GuakeHelper');
  }

  disable() {
    if (this._mapSignalId) {
      global.window_manager.disconnect(this._mapSignalId);
      this._mapSignalId = 0;
    }
    for (const id of this._timers) {
      GLib.source_remove(id);
    }
    this._timers.clear();
    this._pending = null;
    if (this._dbus) {
      this._dbus.flush();
      this._dbus.unexport();
      this._dbus = null;
    }
  }

  _isGuake(win) {
    const wmClass = (win.get_wm_class() || "").toLowerCase();
    const wmInst = (win.get_wm_class_instance() || "").toLowerCase();
    const title = win.get_title() || "";
    return wmClass.includes("guake") || wmInst.includes("guake") || title === "Guake!";
  }

  _unmaximizeIfNeeded(win) {
    const maximized =
      win.maximized_horizontally ||
      win.maximized_vertically ||
      (typeof win.is_maximized === 'function' ? win.is_maximized() : false);
    if (!maximized) return;
    try {
      if (win.unmaximize.length === 0) win.unmaximize();
      else win.unmaximize(Meta.MaximizeFlags.BOTH);
    } catch {
      try { win.unmaximize(); } catch { }
    }
  }

  _applyRect(win, rect) {
    try {
      this._unmaximizeIfNeeded(win);
      win.move_resize_frame(true, rect.x, rect.y, rect.width, rect.height);
      win.activate(global.get_current_time());
    } catch { }
  }

  _addTimer(ms, fn) {
    let id = 0;
    id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
      this._timers.delete(id);
      fn();
      return GLib.SOURCE_REMOVE;
    });
    this._timers.add(id);
  }

  _schedulePlace(win, rect) {
    const winId = win.get_id();
    const findWin = () =>
      global.get_window_actors().find((a) => a.meta_window?.get_id() === winId)?.meta_window || null;

    this._applyRect(win, rect);

    for (const delay of [30, 90, 180]) {
      this._addTimer(delay, () => {
        if (this._pending && this._pending !== rect) return;
        const w = findWin();
        if (!w) return;
        const f = w.get_frame_rect();
        if (
          Math.abs(f.x - rect.x) > 2 ||
          Math.abs(f.y - rect.y) > 2 ||
          Math.abs(f.width - rect.width) > 4 ||
          Math.abs(f.height - rect.height) > 4
        ) {
          this._applyRect(w, rect);
        }
        if (delay === 180 && this._pending === rect) {
          this._pending = null;
        }
      });
    }
  }

  GetPointerMonitor() {
    const [px, py] = global.get_pointer();
    const monitors = Main.layoutManager.monitors;
    let idx = Main.layoutManager.primaryIndex;
    for (let i = 0; i < monitors.length; i++) {
      const m = monitors[i];
      if (px >= m.x && px < m.x + m.width && py >= m.y && py < m.y + m.height) {
        idx = i;
        break;
      }
    }
    const m = monitors[idx];
    const wa = Main.layoutManager.getWorkAreaForMonitor(idx);
    return JSON.stringify({
      px,
      py,
      index: idx,
      x: m.x,
      y: m.y,
      width: m.width,
      height: m.height,
      workX: wa.x,
      workY: wa.y,
      workWidth: wa.width,
      workHeight: wa.height,
    });
  }

  ArmPlacement(x, y, width, height) {
    const rect = {
      x,
      y,
      width,
      height,
      deadline: GLib.get_monotonic_time() + 2000000,
    };
    this._pending = rect;

    // Fallback in case Guake was already mapped without emitting a 'map' signal
    this._addTimer(80, () => {
      if (this._pending !== rect) return;
      const actor = global
        .get_window_actors()
        .find((a) => a.meta_window && this._isGuake(a.meta_window));
      if (actor?.meta_window) {
        this._schedulePlace(actor.meta_window, rect);
      }
    });

    return true;
  }
}
