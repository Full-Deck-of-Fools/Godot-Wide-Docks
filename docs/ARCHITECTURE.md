# Architecture

## Author-facing behavior

Wide Docks should feel like Godot with one restriction removed:

> Grab the normal Scene/Inspector divider and drag it farther.

There is no alternate panel manager and no replacement dock UI.

## Godot editor shape

On the production baseline, the relevant editor hierarchy is effectively:

```text
DockHSplitMain
├── left dock column
├── optional second left dock column
├── CENTER VBoxContainer
│   └── DockVSplitCenter
├── optional first right dock column
└── right dock column
```

Godot's main `SplitContainer` normally stops a divider when the center
workspace reaches the minimum width reported by its contents.

## Wide Docks strategy

Wide Docks does **not** give the CENTER column a maximum width.

Instead, while a divider directly touching CENTER moves, Wide Docks temporarily
caps the internal `DockVSplitCenter`. This lowers the minimum width that CENTER
reports to `DockHSplitMain` without constraining CENTER's own maximum width.

That distinction is what keeps the two center edges independent.

### Drag sequence

```text
native divider receives motion
        ↓
Wide Docks lowers internal center cap
        ↓
Godot's native splitter handles the motion
        ↓
DockHSplitMain performs its queued layout
        ↓
Wide Docks reads CENTER's real resulting width
        ↓
internal center is latched to that real width
```

The release path performs one final sync as a safety net.

## Locked v1 invariants

Future v1 changes must preserve these unless a major-version design explicitly
replaces the contract:

1. Do not reparent live Godot editor controls.
2. Do not use a global `_input()` handler.
3. Do not use a `_process()` correction loop.
4. Do not write `SplitContainer.split_offsets`.
5. Do not add a parallel `InputEventScreenDrag` path.
6. Do not impose a maximum directly on the CENTER column.
7. Left and right center boundaries must remain independent.
8. The internal center must visually latch after native drag layout.
9. Disabling the plugin must restore original sizing/clipping properties.

`scripts/check_release.py` enforces the source-level subset of these rules.

## Why internal editor names are used

Godot currently does not expose a public editor API for changing this
particular center-workspace minimum-width behavior. Wide Docks therefore finds
`DockHSplitMain` and `DockVSplitCenter` by editor node name and fails safely if
the expected structure is not found.

This is the main compatibility risk and the reason new Godot versions should
be tested explicitly.
