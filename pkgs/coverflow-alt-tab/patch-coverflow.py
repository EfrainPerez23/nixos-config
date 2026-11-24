import sys

switcher_path, platform_path, manager_path = sys.argv[1], sys.argv[2], sys.argv[3]


def replace_once(text: str, old: str, new: str, label: str) -> str:
    assert old in text, f"{label} block not found"
    return text.replace(old, new, 1)


# ---------------------------------------------------------------------------
# 1) switcher.js
# ---------------------------------------------------------------------------
with open(switcher_path, "r") as f:
    switcher_js = f.read()

switcher_js = replace_once(
    switcher_js,
    "        this._animatingClosed = false;\n"
    "        this._dBus = dBus;\n"
    "        this._fromIndex = currentIndex;\n"
    "        this._toIndex = currentIndex;\n"
    "        this._destroyed = false;",
    "        this._animatingClosed = false;\n"
    "        this._destroyFallbackTimeoutId = 0;\n"
    "        this._dBus = dBus;\n"
    "        this._fromIndex = currentIndex;\n"
    "        this._toIndex = currentIndex;\n"
    "        this._destroyed = false;",
    "switcher constructor fields",
)

switcher_js = replace_once(
    switcher_js,
    "    show() {\n"
    "        // create previews",
    "    show() {\n"
    "        if (this.isDestroyed())\n"
    "            return GLib.SOURCE_REMOVE;\n"
    "        // create previews",
    "switcher show() guard",
)

switcher_js = replace_once(
    switcher_js,
    "                    this._hiddenWindowActors.push(child);\n"
    "                    child.hide();",
    "                    if (child.visible) {\n"
    "                        this._hiddenWindowActors.push(child);\n"
    "                        child.hide();\n"
    "                    }",
    "switcher show() track only visible hidden actors",
)

switcher_js = replace_once(
    switcher_js,
    "        if (this._parent === null) {\n"
    "            let currentWorkspace = this._manager.workspace_manager.get_active_workspace();\n"
    "            for (let child of global.window_group.get_children()) {\n"
    "                if (typeof child.get_meta_window === \"function\") {\n"
    "                    let metaWin = child.get_meta_window();\n"
    "                    // Only re-show windows that belong to the current workspace.\n"
    "                    // Re-showing windows from other workspaces is what left them\n"
    "                    // ghosting on the current workspace after a switch.\n"
    "                    if (!metaWin.minimized && metaWin.get_workspace() === currentWorkspace) {\n"
    "                        child.show();\n"
    "                    }\n"
    "                }\n"
    "            }\n"
    "        }",
    "        if (this._parent === null) {\n"
    "            let currentWorkspace = this._manager.workspace_manager.get_active_workspace();\n"
    "            for (let child of this._hiddenWindowActors ?? []) {\n"
    "                if (typeof child.get_meta_window === \"function\") {\n"
    "                    let metaWin = child.get_meta_window();\n"
    "                    if (metaWin && !metaWin.minimized && metaWin.get_workspace() === currentWorkspace) {\n"
    "                        child.show();\n"
    "                    }\n"
    "                }\n"
    "            }\n"
    "            this._hiddenWindowActors = [];\n"
    "        }",
    "switcher destroy() restore only hidden actors",
)

switcher_js = replace_once(
    switcher_js,
    "        this._getSwitcherBackgroundColor();\n"
    "    }",
    "        this._getSwitcherBackgroundColor();\n"
    "        return GLib.SOURCE_REMOVE;\n"
    "    }",
    "switcher show() return",
)

switcher_js = replace_once(
    switcher_js,
    "    _stopClosing() {\n"
    "        this._animatingClosed = false;\n"
    "        this._swipeTracker.enabled = true;",
    "    _stopClosing() {\n"
    "        this._animatingClosed = false;\n"
    "        this._numPreviewsComplete = 0;\n"
    "        if (this._destroyFallbackTimeoutId !== 0) {\n"
    "            GLib.Source.remove(this._destroyFallbackTimeoutId);\n"
    "            this._destroyFallbackTimeoutId = 0;\n"
    "        }\n"
    "        this._swipeTracker.enabled = true;",
    "switcher _stopClosing()",
)

switcher_js = replace_once(
    switcher_js,
    "    _next() {\n"
    "        if (this._parent === null) this._manager.platform.dimBackground();\n"
    "        this._stopClosing();",
    "    _next() {\n"
    "        if (this._initialDelayTimeoutId !== 0) {\n"
    "            if (this._windows.length > 0)\n"
    "                this._setCurrentIndex((this._currentIndex + 1) % this._windows.length);\n"
    "            return;\n"
    "        }\n"
    "        if (this._parent === null) this._manager.platform.dimBackground();\n"
    "        this._stopClosing();",
    "switcher _next() pre-show guard",
)

switcher_js = replace_once(
    switcher_js,
    "    _previous() {\n"
    "        if (this._parent ===  null) this._manager.platform.dimBackground();\n"
    "        this._stopClosing();",
    "    _previous() {\n"
    "        if (this._initialDelayTimeoutId !== 0) {\n"
    "            if (this._windows.length > 0)\n"
    "                this._setCurrentIndex((this._currentIndex - 1 + this._windows.length) % this._windows.length);\n"
    "            return;\n"
    "        }\n"
    "        if (this._parent ===  null) this._manager.platform.dimBackground();\n"
    "        this._stopClosing();",
    "switcher _previous() pre-show guard",
)

switcher_js = replace_once(
    switcher_js,
    "    _raiseIcons() {\n"
    "        for (let i = 0; i < this._windows.length; i++) {\n"
    "            this.previewActor.set_child_above_sibling(this._windowIconBoxes[i], null);\n"
    "            this.previewActor.set_child_above_sibling(this._windowTitles[i], null);\n"
    "        }\n"
    "    }",
    "    _raiseIcons() {\n"
    "        if (!this._windows || !this.previewActor)\n"
    "            return;\n"
    "        for (let i = 0; i < this._windows.length; i++) {\n"
    "            const iconBox = this._windowIconBoxes?.[i];\n"
    "            if (iconBox && iconBox.get_parent() === this.previewActor)\n"
    "                this.previewActor.set_child_above_sibling(iconBox, null);\n"
    "            const title = this._windowTitles?.[i];\n"
    "            if (title && title.get_parent() === this.previewActor)\n"
    "                this.previewActor.set_child_above_sibling(title, null);\n"
    "        }\n"
    "    }",
    "switcher _raiseIcons() guard",
)

switcher_js = replace_once(
    switcher_js,
    "        if (this._parent === null && this._initialDelayTimeoutId !== 0) {\n"
    "            GLib.Source.remove(this._initialDelayTimeoutId);\n"
    "        }",
    "        if (this._parent === null && this._initialDelayTimeoutId !== 0) {\n"
    "            GLib.Source.remove(this._initialDelayTimeoutId);\n"
    "        }\n"
    "        if (this._destroyFallbackTimeoutId !== 0) {\n"
    "            GLib.Source.remove(this._destroyFallbackTimeoutId);\n"
    "            this._destroyFallbackTimeoutId = 0;\n"
    "        }",
    "switcher destroy() fallback timer cleanup",
)

switcher_js = replace_once(
    switcher_js,
    "    animateClosed(reason=CloseReason.ACTIVATE_SELECTED) {\n"
    "        if (this._animatingClosed) return;\n"
    "        this._animatingClosed = true;",
    "    animateClosed(reason=CloseReason.ACTIVATE_SELECTED) {\n"
    "        if (this._animatingClosed) return;\n"
    "        this._animatingClosed = true;\n"
    "        this._numPreviewsComplete = 0;",
    "switcher animateClosed() reset counter",
)

switcher_js = replace_once(
    switcher_js,
    "            if (reason === CloseReason.ACTIVATE_SELECTED) {\n"
    "                for (let [i, preview] of this._previews.entries()) {\n"
    "                    let metaWin = preview.metaWin;",
    "            if (reason === CloseReason.ACTIVATE_SELECTED) {\n"
    "                if (!this._previews || this._previews.length === 0) {\n"
    "                    if (this._parent === null)\n"
    "                        this.destroy();\n"
    "                    return;\n"
    "                }\n"
    "                if (this._parent === null) {\n"
    "                    if (this._destroyFallbackTimeoutId !== 0)\n"
    "                        GLib.Source.remove(this._destroyFallbackTimeoutId);\n"
    "                    const fallbackMs = Math.ceil(this._settings.animation_time * 1000) + 150;\n"
    "                    this._destroyFallbackTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, fallbackMs, () => {\n"
    "                        this._destroyFallbackTimeoutId = 0;\n"
    "                        if (!this.isDestroyed())\n"
    "                            this.destroy();\n"
    "                        return GLib.SOURCE_REMOVE;\n"
    "                    });\n"
    "                }\n"
    "                for (let [i, preview] of this._previews.entries()) {\n"
    "                    if (!preview) {\n"
    "                        this._onPreviewAnimationComplete();\n"
    "                        continue;\n"
    "                    }\n"
    "                    let metaWin = preview.metaWin;",
    "switcher animateClosed() fallback timeout",
)

switcher_js = replace_once(
    switcher_js,
    "                if (this._currentIndex >= 0) {\n"
    "                    let current_preview = this._previews[Math.round(this._currentIndex)];\n"
    "                    let current_preview_transient = current_preview.metaWin.get_transient_for()",
    "                if (this._currentIndex >= 0) {\n"
    "                    let current_preview = this._previews[Math.round(this._currentIndex)];\n"
    "                    if (!current_preview) {\n"
    "                        this._raiseIcons();\n"
    "                        return;\n"
    "                    }\n"
    "                    let current_preview_transient = current_preview.metaWin.get_transient_for()",
    "switcher animateClosed() current_preview guard",
)

with open(switcher_path, "w") as f:
    f.write(switcher_js)


# ---------------------------------------------------------------------------
# 2) platform.js
# ---------------------------------------------------------------------------
with open(platform_path, "r") as f:
    platform_js = f.read()

platform_js = replace_once(
    platform_js,
    "        this._settings_changed_callbacks = null;\n"
    "        this._themeContext = null;\n"
    "        this._logger = logger;\n"
    "    }",
    "        this._settings_changed_callbacks = null;\n"
    "        this._themeContext = null;\n"
    "        this._logger = logger;\n"
    "        this._backgroundGroup = null;\n"
    "        this._backgroundShade = null;\n"
    "        this._backgroundManagers = [];\n"
    "    }",
    "platform constructor background fields",
)

platform_js = replace_once(
    platform_js,
    "    disable() {\n"
    "        this.showPanels(0);",
    "    disable() {\n"
    "        this.removeBackground();\n"
    "        this.showPanels(0);",
    "platform disable() removeBackground",
)

platform_js = replace_once(
    platform_js,
    "    initBackground(monitor=null) {\n"
    "        this._backgroundGroup = new Meta.BackgroundGroup();",
    "    _sweepBackgroundGroups() {\n"
    "        if (this._backgroundShade) {\n"
    "            this._backgroundShade.remove_all_transitions();\n"
    "        }\n"
    "        if (this._backgroundGroup) {\n"
    "            this._backgroundGroup.remove_all_transitions();\n"
    "            this._backgroundGroup.hide();\n"
    "        }\n"
    "        for (const mgr of this._backgroundManagers ?? []) {\n"
    "            try {\n"
    "                mgr.destroy();\n"
    "            } catch {\n"
    "                // Already destroyed.\n"
    "            }\n"
    "        }\n"
    "        this._backgroundManagers = [];\n"
    "        if (this._backgroundGroup) {\n"
    "            this._backgroundGroup.destroy();\n"
    "            this._backgroundGroup = null;\n"
    "        }\n"
    "        this._backgroundShade = null;\n"
    "        for (const child of Main.uiGroup.get_children()) {\n"
    "            if (child.get_name?.() === 'coverflow-alt-tab-background-group') {\n"
    "                child.remove_all_transitions();\n"
    "                child.hide();\n"
    "                child.destroy();\n"
    "            }\n"
    "        }\n"
    "    }\n\n"
    "    initBackground(monitor=null) {\n"
    "        this._sweepBackgroundGroups();\n"
    "        this._backgroundGroup = new Meta.BackgroundGroup();",
    "platform initBackground() cleanup",
)

platform_js = replace_once(
    platform_js,
    "        for (let currentMonitor of monitors) {\n"
    "            new Background.BackgroundManager({\n"
    "                container: this._backgroundGroup,\n"
    "                monitorIndex: currentMonitor.index,\n"
    "                vignette: false,\n"
    "            });\n"
    "        }",
    "        for (let currentMonitor of monitors) {\n"
    "            this._backgroundManagers.push(new Background.BackgroundManager({\n"
    "                container: this._backgroundGroup,\n"
    "                monitorIndex: currentMonitor.index,\n"
    "                vignette: false,\n"
    "            }));\n"
    "        }",
    "platform initBackground() track BackgroundManager",
)

platform_js = replace_once(
    platform_js,
    "        this._backgroundGroup.show();\n"
    "        this.tween(this._backgroundGroup, {",
    "        if (!this._backgroundGroup || !this._backgroundShade)\n"
    "            return;\n"
    "        this._backgroundGroup.show();\n"
    "        this.tween(this._backgroundGroup, {",
    "platform dimBackground() guard",
)

platform_js = replace_once(
    platform_js,
    "        this.tween(this._backgroundGroup, {\n"
    "            opacity: 0,",
    "        if (!this._backgroundGroup || !this._backgroundShade)\n"
    "            return;\n"
    "        this.tween(this._backgroundGroup, {\n"
    "            opacity: 0,",
    "platform lightenBackground() guard",
)

platform_js = replace_once(
    platform_js,
    "        if (this._settings.hide_panel)\n"
    "            this.showPanels(0);\n"
    "\n"
    "        if (this._backgroundGroup)\n"
    "            this._backgroundGroup.destroy();\n"
    "        this._backgroundGroup = null;\n"
    "        this._backgroundShade = null;",
    "        if (this._settings?.hide_panel)\n"
    "            this.showPanels(0);\n"
    "\n"
    "        this._sweepBackgroundGroups();",
    "platform removeBackground() sweep",
)

with open(platform_path, "w") as f:
    f.write(platform_js)


# ---------------------------------------------------------------------------
# 3) manager.js
# ---------------------------------------------------------------------------
with open(manager_path, "r") as f:
    manager_js = f.read()

manager_js = replace_once(
    manager_js,
    "        if (windows.length) {\n"
    "            const currentIndex = 0;\n"
    "            let switcher_class = this.platform.getSettings().switcher_class;\n"
    "            this.switcher = new switcher_class(windows, mask, currentIndex, this, activeMonitor, isApplicationSwitcher, null, dBus);\n"
    "        }",
    "        if (windows.length) {\n"
    "            if (this.switcher && !this.switcher.isDestroyed()) {\n"
    "                this.switcher.destroy();\n"
    "                this.switcher = null;\n"
    "            }\n"
    "            const currentIndex = 0;\n"
    "            let switcher_class = this.platform.getSettings().switcher_class;\n"
    "            this.switcher = new switcher_class(windows, mask, currentIndex, this, activeMonitor, isApplicationSwitcher, null, dBus);\n"
    "        }",
    "manager _startWindowSwitcherInternal() destroy previous switcher",
)

with open(manager_path, "w") as f:
    f.write(manager_js)
