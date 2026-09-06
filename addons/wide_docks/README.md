# Wide Docks 1.0.0

Wide Docks lets Godot's side editor docks expand farther on narrow/mobile
screens while preserving the native divider interaction.

## Enable

1. Keep this folder at `res://addons/wide_docks/`.
2. Open **Project → Project Settings → Plugins**.
3. Enable **Wide Docks**.
4. Drag the normal divider beside Scene or Inspector.

There are no extra UI controls.

## Baseline compatibility

Verified production baseline: **Godot 4.7.2 stable**, including the Android
editor.

The implementation relies on internal editor node names (`DockHSplitMain` and
`DockVSplitCenter`), so test compatibility before claiming support for a newer
Godot version.

Project documentation:
https://github.com/Full-Deck-of-Fools/Godot-Wide-Side-Panels

Attribution:
- No credit is required in games/projects merely created with Wide Docks.
- Tooling products that redistribute or substantially derive from Wide Docks
  must visibly credit FDOF (Full Deck of Fools).

License: FDOF Tooling Attribution License 1.0.
