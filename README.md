# Wide Docks

**Wide Docks** is a small Godot editor plugin that lets the Scene, FileSystem, Inspector, and other side docks expand farther into the editor workspace than Godot normally allows.

It is designed first for **Godot on phones and tablets**, where the default center-workspace minimum can leave too little room for long Scene Tree names, Inspector properties, resource paths, and documentation text.

**Official version:** `1.0.0`  
**Production baseline:** Godot `4.7.2.stable`  
**Primary target:** Android editor / narrow displays  
**Category:** Godot → Editor → Mobile → Accessibility → Production Ready

## Why it exists

On a narrow screen, Godot's native side-dock divider stops once the center editor reaches its minimum width. That is reasonable on a desktop monitor, but on mobile it can make the side dock harder to read than the temporarily hidden center workspace.

Wide Docks removes that practical limitation while keeping the normal Godot drag interaction.

## Features

- Drag left and right editor docks much farther inward.
- Left and right center boundaries remain independent.
- Uses Godot's existing native splitter interaction.
- Visually follows the divider throughout the drag.
- No toolbar, settings page, or alternate dock UI.
- No runtime/game dependency: editor-only.
- Disabling the plugin restores the original editor sizing properties.

## Installation

Copy `addons/wide_docks/` into your project, then enable **Wide Docks** in **Project → Project Settings → Plugins**.

## Compatibility

The `1.0.x` line is verified against Godot `4.7.2`. Wide Docks accesses internal editor controls named `DockHSplitMain` and `DockVSplitCenter`, so future Godot editor changes may require compatibility updates.

## License

Wide Docks uses the **FDOF Tooling Attribution License 1.0**.

Ordinary use while creating a game, application, asset, or other project does **not** require visible credit to FDOF.

Visible credit to **FDOF (Full Deck of Fools)** is required when Wide Docks, a modified version, or a substantial portion of its implementation is redistributed as part of another editor, plugin, toolkit, SDK, authoring system, or similar tooling product.

See [LICENSE](LICENSE) for the full terms.

## Repository

https://github.com/Full-Deck-of-Fools/Godot-Wide-Side-Panels
