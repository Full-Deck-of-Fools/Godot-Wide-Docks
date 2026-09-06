# Maintainer Testing

Run these checks before every release.

## 1. Static release guard

From the repository root:

```bash
python scripts/check_release.py
```

This verifies packaging metadata and the locked v1 source invariants.

## 2. Clean install

1. Copy only `addons/wide_docks/` into a normal Godot project.
2. Start the target Godot version.
3. Enable Wide Docks.
4. Confirm no errors appear on enable.

## 3. Core mobile interaction

On Android:

1. Drag the Scene-side boundary farther toward the center than stock Godot
   permits.
2. Keep the pointer held and move back and forth across the old stock limit.
3. Confirm the center contents visually track the actual boundary.
4. Release and confirm the boundary remains exactly where it landed.
5. Repeat on the Inspector-side boundary.
6. Confirm dragging one boundary does not move the other boundary.

## 4. Stress cycle

Repeat at least ten times:

- narrow center;
- widen center;
- switch which side is being dragged;
- release at different widths.

Look for flicker, snap-back, opposite-side movement, or accumulating offset.

## 5. Editor lifecycle

Verify:

- reopen project;
- rescan filesystem / refresh scripts;
- switch 2D / 3D / Script workspaces;
- open a scene with a Camera3D;
- disable and re-enable the plugin.

There should be no duplicate-signal errors, "Camera is not inside scene"
errors, renderer instance-null errors, or editor viewport initialization
errors.

## 6. Disable restoration

After disabling Wide Docks, verify Godot returns to its normal minimum-width
behavior.

## Release rule

A compatibility row should be marked production-ready only after the manual
interaction matrix is completed on that exact Godot version/platform.
