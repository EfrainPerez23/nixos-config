import sys

handlers_path, manager_path = sys.argv[1], sys.argv[2]


def replace_once(text: str, old: str, new: str, label: str) -> str:
    assert old in text, f"{label} block not found"
    return text.replace(old, new, 1)


# 1) manager/event_handlers.js: restack shadow actors even when the window actor
# is temporarily hidden (e.g. during Coverflow Alt-Tab), and guard parent checks
# to avoid clutter_actor_set_child_below_sibling warnings.
with open(handlers_path, "r") as f:
    handlers_js = f.read()

handlers_js = replace_once(
    handlers_js,
    "export function onRestacked() {\n"
    "    for (const actor of global.get_window_actors()) {\n"
    "        const shadow = actor.rwcCustomData?.shadow;\n"
    "        if (!(actor.visible && shadow)) {\n"
    "            continue;\n"
    "        }\n"
    "        global.windowGroup.set_child_below_sibling(shadow, actor);\n"
    "    }\n"
    "}",
    "export function onRestacked() {\n"
    "    for (const actor of global.get_window_actors()) {\n"
    "        const shadow = actor.rwcCustomData?.shadow;\n"
    "        if (!shadow) {\n"
    "            continue;\n"
    "        }\n"
    "        if (actor.get_parent() !== global.windowGroup ||\n"
    "            shadow.get_parent() !== global.windowGroup) {\n"
    "            continue;\n"
    "        }\n"
    "        global.windowGroup.set_child_below_sibling(shadow, actor);\n"
    "    }\n"
    "}",
    "onRestacked()",
)

with open(handlers_path, "w") as f:
    f.write(handlers_js)


# 2) manager/event_manager.js: re-sync shadow stacking whenever a window actor
# becomes visible again after being temporarily hidden by another extension.
with open(manager_path, "r") as f:
    manager_js = f.read()

manager_js = replace_once(
    manager_js,
    "    // Workspace or monitor of the window changed.\n"
    "    connect(actor.metaWindow, 'workspace-changed', () => {\n"
    "        if (actor.metaWindow) {\n"
    "            handlers.onFocusChanged(actor);\n"
    "        }\n"
    "    });\n"
    "    handlers.onAddEffect(actor);",
    "    // Workspace or monitor of the window changed.\n"
    "    connect(actor.metaWindow, 'workspace-changed', () => {\n"
    "        if (actor.metaWindow) {\n"
    "            handlers.onFocusChanged(actor);\n"
    "        }\n"
    "    });\n"
    "    // Re-sync shadow z-order when a hidden window actor becomes visible again.\n"
    "    connect(actor, 'notify::visible', () => {\n"
    "        if (actor.visible && actor.rwcCustomData?.shadow) {\n"
    "            handlers.onRestacked();\n"
    "        }\n"
    "    });\n"
    "    handlers.onAddEffect(actor);",
    "applyEffectTo() notify::visible",
)

with open(manager_path, "w") as f:
    f.write(manager_js)
