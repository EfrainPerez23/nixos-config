import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { MusicController } from './src/controller.js';

export default class DynamicMusicExtension extends Extension {
    enable() {
        if (this._controller) {
            this.disable();
        }
        this._settings = this.getSettings();
        this._extraControllers = new Map();
        this._dtpSignalId = 0;
        this._monitorsSignalId = 0;
        this._syncTimerId = 0;

        this._controller = new MusicController(this, null);
        this._controller.enable();

        this._bindDashToPanel();
        this._monitorsSignalId = Main.layoutManager.connect('monitors-changed', () => {
            this._scheduleSync(400);
        });
        this._scheduleSync(1200);
    }

    _bindDashToPanel() {
        if (!this._dtpSignalId && global.dashToPanel?.connect) {
            try {
                this._dtpSignalId = global.dashToPanel.connect('panels-created', () => {
                    this._scheduleSync(300);
                });
            } catch (_e) {}
        }
    }

    _scheduleSync(delayMs) {
        if (this._syncTimerId) {
            GLib.Source.remove(this._syncTimerId);
            this._syncTimerId = 0;
        }
        this._syncTimerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, delayMs, () => {
            this._syncTimerId = 0;
            this._bindDashToPanel();
            this._syncExtraPanels();
            return GLib.SOURCE_REMOVE;
        });
    }

    _syncExtraPanels() {
        if (!this._settings) return;
        const dtpPanels = global.dashToPanel?.panels || [];
        const secondaryPanels = new Set();
        for (const dtpPanel of dtpPanels) {
            const p = dtpPanel?.panel;
            if (p && p !== Main.panel && p._centerBox) {
                secondaryPanels.add(p);
            }
        }

        for (const [panel, ctrl] of Array.from(this._extraControllers.entries())) {
            if (!secondaryPanels.has(panel)) {
                try { ctrl.disable(); } catch (_e) {}
                this._extraControllers.delete(panel);
            }
        }

        for (const panel of secondaryPanels) {
            if (!this._extraControllers.has(panel)) {
                try {
                    const ctrl = new MusicController(this, panel);
                    ctrl.enable();
                    this._extraControllers.set(panel, ctrl);
                } catch (e) {
                    console.error('[Dynamic Music Pill] Secondary monitor init error:', e);
                }
            }
        }
    }

    disable() {
        if (this._syncTimerId) {
            GLib.Source.remove(this._syncTimerId);
            this._syncTimerId = 0;
        }
        if (this._dtpSignalId && global.dashToPanel?.disconnect) {
            try { global.dashToPanel.disconnect(this._dtpSignalId); } catch (_e) {}
            this._dtpSignalId = 0;
        }
        if (this._monitorsSignalId) {
            Main.layoutManager.disconnect(this._monitorsSignalId);
            this._monitorsSignalId = 0;
        }
        if (this._extraControllers) {
            for (const ctrl of this._extraControllers.values()) {
                try { ctrl.disable(); } catch (_e) {}
            }
            this._extraControllers.clear();
            this._extraControllers = null;
        }
        if (this._controller) {
            this._controller.disable();
            this._controller = null;
        }
        this._settings = null;
    }
}
