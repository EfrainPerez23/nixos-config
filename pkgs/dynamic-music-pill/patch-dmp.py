import sys

ctrl_path, pill_path, exp_path, vis_path, utils_path = sys.argv[1:6]

# 1) Patch src/controller.js to accept an optional panelOverride for secondary monitors
with open(ctrl_path, "r") as f:
    c = f.read()

repls_c = [
    (
        "    constructor(extension) {\n        this._extension = extension;",
        "    constructor(extension, panelOverride = null) {\n        this._extension = extension;\n        this._panelOverride = panelOverride;",
    ),
    (
        "        this._settings.connectObject('changed::hide-default-player', () => this._updateDefaultPlayerVisibility(), this);",
        "        if (!this._panelOverride) this._settings.connectObject('changed::hide-default-player', () => this._updateDefaultPlayerVisibility(), this);",
    ),
    (
        "        this._updateDefaultPlayerVisibility();\n        this._createLyricProxy();",
        "        if (!this._panelOverride) {\n            this._updateDefaultPlayerVisibility();\n            this._createLyricProxy();\n        }",
    ),
    (
        "        this._updateDefaultPlayerVisibility(true);",
        "        if (!this._panelOverride) this._updateDefaultPlayerVisibility(true);",
    ),
    (
        "        SharedVisualizerEngine.destroy();",
        "        if (!this._panelOverride) SharedVisualizerEngine.destroy();",
    ),
    (
        "            } else if (target === 1) expectedContainer = Main.panel._leftBox;\n"
        "            else if (target === 2) expectedContainer = Main.panel._centerBox;\n"
        "            else if (target === 3) expectedContainer = Main.panel._rightBox;",
        "            } else if (target === 1) expectedContainer = (this._panelOverride || Main.panel)._leftBox;\n"
        "            else if (target === 2) expectedContainer = (this._panelOverride || Main.panel)._centerBox;\n"
        "            else if (target === 3) expectedContainer = (this._panelOverride || Main.panel)._rightBox;",
    ),
    (
        "        } else if (target === 1) container = Main.panel._leftBox;\n"
        "        else if (target === 2) container = Main.panel._centerBox;\n"
        "        else if (target === 3) container = Main.panel._rightBox;",
        "        } else if (target === 1) container = (this._panelOverride || Main.panel)._leftBox;\n"
        "        else if (target === 2) container = (this._panelOverride || Main.panel)._centerBox;\n"
        "        else if (target === 3) container = (this._panelOverride || Main.panel)._rightBox;",
    ),
    (
        "            } else if (target === 1) container = Main.panel._leftBox;\n"
        "            else if (target === 2) container = Main.panel._centerBox;\n"
        "            else if (target === 3) container = Main.panel._rightBox;",
        "            } else if (target === 1) container = (this._panelOverride || Main.panel)._leftBox;\n"
        "            else if (target === 2) container = (this._panelOverride || Main.panel)._centerBox;\n"
        "            else if (target === 3) container = (this._panelOverride || Main.panel)._rightBox;",
    ),
]
for old_s, new_s in repls_c:
    assert old_s in c, f"Pattern not found in controller.js: {old_s[:60]}"
    c = c.replace(old_s, new_s, 1)
assert "Main.panel._centerBox" not in c, "Remaining hardcoded Main.panel._centerBox in controller.js"

with open(ctrl_path, "w") as f:
    f.write(c)

# 2) Patch src/uiMusicPill.js so hover only opens (never toggles closed if already open)
with open(pill_path, "r") as f:
    p = f.read()

old_hover = (
    "                    let action = this._settings.get_string('action-hover');\n"
    "                    if (action && action !== 'none') {\n"
    "                        this._controller.performAction(action);\n"
    "                    }"
)

new_hover = (
    "                    let action = this._settings.get_string('action-hover');\n"
    "                    if (action === 'toggle_menu' && this._controller._expandedPlayer) {\n"
    "                        return GLib.SOURCE_REMOVE;\n"
    "                    }\n"
    "                    if (action && action !== 'none') {\n"
    "                        this._controller.performAction(action);\n"
    "                    }"
)

assert old_hover in p, "Hover block not found in uiMusicPill.js"
p = p.replace(old_hover, new_hover, 1)

with open(pill_path, "w") as f:
    f.write(p)

# 3) Patch src/uiExpandedPlayer.js to track real pointer coords (pill + bridge + popup)
# instead of Clutter leave-event, avoiding flicker caused by _backgroundBtn covering the pill.
with open(exp_path, "r") as f:
    e = f.read()

old_exp_hover = (
    "            this._box.connectObject('enter-event', () => {\n"
    "                if (this._leaveHideTimeoutId) {\n"
    "                    GLib.Source.remove(this._leaveHideTimeoutId);\n"
    "                    this._leaveHideTimeoutId = null;\n"
    "                }\n"
    "                return Clutter.EVENT_PROPAGATE;\n"
    "            }, this);\n\n"
    "            this._box.connectObject('leave-event', () => {\n"
    "                if (this._settings.get_boolean('popup-hide-on-leave')) {\n"
    "                    if (this._leaveHideTimeoutId) GLib.Source.remove(this._leaveHideTimeoutId);\n"
    "                    this._leaveHideTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 300, () => {\n"
    "                        this._leaveHideTimeoutId = null;\n"
    "                        this.hide();\n"
    "                        return GLib.SOURCE_REMOVE;\n"
    "                    });\n"
    "                }\n"
    "                return Clutter.EVENT_PROPAGATE;\n"
    "            }, this);"
)

new_exp_hover = (
    "            this._outsideTicks = 0;\n"
    "            this._hoverPollId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, () => {\n"
    "                if (!this.visible || !this._settings.get_boolean('popup-hide-on-leave')) {\n"
    "                    this._outsideTicks = 0;\n"
    "                    return GLib.SOURCE_CONTINUE;\n"
    "                }\n"
    "                const [mx, my] = global.get_pointer();\n"
    "                const pad = 14;\n"
    "                let inSafe = false;\n"
    "                try {\n"
    "                    const [bx, by] = this._box.get_transformed_position();\n"
    "                    const [bw, bh] = this._box.get_transformed_size();\n"
    "                    if (bw > 0 && bh > 0 && mx >= bx - pad && mx <= bx + bw + pad && my >= by - pad && my <= by + bh + pad) {\n"
    "                        inSafe = true;\n"
    "                    }\n"
    "                    const pill = this._controller?._pill;\n"
    "                    if (!inSafe && pill && pill.get_parent()) {\n"
    "                        const [px, py] = pill.get_transformed_position();\n"
    "                        const [pw, ph] = pill.get_transformed_size();\n"
    "                        if (pw > 0 && ph > 0 && mx >= px - pad && mx <= px + pw + pad && my >= py - pad && my <= py + ph + pad) {\n"
    "                            inSafe = true;\n"
    "                        }\n"
    "                        if (!inSafe && bw > 0 && pw > 0) {\n"
    "                            const left = Math.min(px, bx) - pad;\n"
    "                            const right = Math.max(px + pw, bx + bw) + pad;\n"
    "                            const top = Math.min(py, by);\n"
    "                            const bottom = Math.max(py + ph, by + bh);\n"
    "                            if (mx >= left && mx <= right && my >= top && my <= bottom) {\n"
    "                                inSafe = true;\n"
    "                            }\n"
    "                        }\n"
    "                    }\n"
    "                } catch (_err) {\n"
    "                    inSafe = true;\n"
    "                }\n"
    "                if (inSafe) {\n"
    "                    this._outsideTicks = 0;\n"
    "                } else {\n"
    "                    this._outsideTicks++;\n"
    "                    if (this._outsideTicks >= 2) {\n"
    "                        this._hoverPollId = null;\n"
    "                        this.hide();\n"
    "                        return GLib.SOURCE_REMOVE;\n"
    "                    }\n"
    "                }\n"
    "                return GLib.SOURCE_CONTINUE;\n"
    "            });"
)

old_cleanup = "            if (this._leaveHideTimeoutId) { GLib.Source.remove(this._leaveHideTimeoutId); this._leaveHideTimeoutId = null; }"
new_cleanup = (
    "            if (this._leaveHideTimeoutId) { GLib.Source.remove(this._leaveHideTimeoutId); this._leaveHideTimeoutId = null; }\n"
    "            if (this._hoverPollId) { GLib.Source.remove(this._hoverPollId); this._hoverPollId = null; }"
)

old_tick_timer = "            this._updateTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, () => {"
new_tick_timer = "            this._updateTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {"

old_open_anim = "                    duration: 230,\n                    mode: Clutter.AnimationMode.EASE_OUT_EXPO,"
new_open_anim = "                    duration: 140,\n                    mode: Clutter.AnimationMode.EASE_OUT_EXPO,"

old_close_anim = "                    duration: 170,\n                    mode: Clutter.AnimationMode.EASE_OUT_CUBIC,"
new_close_anim = "                    duration: 120,\n                    mode: Clutter.AnimationMode.EASE_OUT_CUBIC,"

assert old_exp_hover in e, "Hover block not found in uiExpandedPlayer.js"
assert old_cleanup in e, "Cleanup block not found in uiExpandedPlayer.js"
assert old_tick_timer in e, "Tick timer block not found in uiExpandedPlayer.js"
assert old_open_anim in e, "Open animation block not found in uiExpandedPlayer.js"
assert old_close_anim in e, "Close animation block not found in uiExpandedPlayer.js"
e = e.replace(old_exp_hover, new_exp_hover, 1)
e = e.replace(old_cleanup, new_cleanup, 1)
e = e.replace(old_tick_timer, new_tick_timer, 1)
e = e.replace(old_open_anim, new_open_anim, 1)
e = e.replace(old_close_anim, new_close_anim, 1)

with open(exp_path, "w") as f:
    f.write(e)

# 4) Patch src/visualizerEngine.js: run cava at 30 FPS / 32 bars instead of 60 FPS / 64 bars
# to cut GNOME Shell main-thread Cairo repaint load in half on Intel iGPUs.
with open(vis_path, "r") as f:
    v = f.read()

old_bars = "        this._fixedBarCount = 64;"
new_bars = "        this._fixedBarCount = 32;"
old_fps = "                      `framerate = 60\\n` +"
new_fps = "                      `framerate = 30\\n` +"

assert old_bars in v, "_fixedBarCount not found in visualizerEngine.js"
assert old_fps in v, "framerate = 60 not found in visualizerEngine.js"
v = v.replace(old_bars, new_bars, 1)
v = v.replace(old_fps, new_fps, 1)

with open(vis_path, "w") as f:
    f.write(v)

# 5) Patch src/utils.js: safely unpack int64/uint64 GLib.Variants without triggering GJS
# precision warnings (INT64_MAX from Chrome/YouTube MPRIS flooding journald).
with open(utils_path, "r") as f:
    u = f.read()

old_unpack = (
    "    if (value instanceof GLib.Variant) {\n"
    "        return smartUnpack(value.deep_unpack()); \n"
    "    }"
)
new_unpack = (
    "    if (value instanceof GLib.Variant) {\n"
    "        let t = value.get_type_string();\n"
    "        if (t === 'v') return smartUnpack(value.get_variant());\n"
    "        if (t === 'x' || t === 't') {\n"
    "            let n = Number(value.print(false));\n"
    "            return (Number.isFinite(n) && Math.abs(n) <= Number.MAX_SAFE_INTEGER) ? n : 0;\n"
    "        }\n"
    "        return smartUnpack(value.deep_unpack());\n"
    "    }"
)

assert old_unpack in u, "smartUnpack block not found in utils.js"
u = u.replace(old_unpack, new_unpack, 1)

with open(utils_path, "w") as f:
    f.write(u)
