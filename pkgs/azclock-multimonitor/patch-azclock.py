import sys
p = sys.argv[1]
with open(p, "r") as f:
    s = f.read()
old_fn = (
    "    setPositionFromSettings() {\n"
    "        const {x, y} = this._getPosition();\n\n"
    "        this.set_position(x, y);\n"
    "        this.queue_relayout();\n"
    "    }"
)
new_fn = (
    "    setPositionFromSettings() {\n"
    "        let hasMonitor = true;\n"
    "        try {\n"
    "            const locationData = JSON.parse(this._settings.get_string('location-data'));\n"
    "            hasMonitor = Boolean(Main.layoutManager.monitors[locationData.monitorIndex]);\n"
    "        } catch (_e) {}\n"
    "        this.visible = hasMonitor;\n"
    "        if (!hasMonitor)\n"
    "            return;\n\n"
    "        const {x, y} = this._getPosition();\n\n"
    "        this.set_position(x, y);\n"
    "        this.queue_relayout();\n"
    "    }"
)
assert old_fn in s, "setPositionFromSettings not found in azclock"
s = s.replace(old_fn, new_fn, 1)
with open(p, "w") as f:
    f.write(s)
