# Compatibility

## Supported production baseline

| Godot | Platform | Status |
|---|---|---|
| 4.7.2 stable | Android editor | Production baseline / verified manually |
| 4.7.2 stable | Desktop editor | Expected from same editor hierarchy; verify before advertising |
| Other 4.7.x | Any | Not automatically claimed |
| 4.8+ | Any | Requires explicit compatibility test |

## Why support is version-sensitive

Wide Docks uses normal `EditorPlugin`, `Control`, and `SplitContainer`
behavior, but it must locate internal editor controls named:

- `DockHSplitMain`
- `DockVSplitCenter`

A Godot release can change editor hierarchy or sizing behavior without
breaking the public `EditorPlugin` API.

## Compatibility policy

Do not widen the advertised Godot version range based only on the plugin
loading without errors.

For each newly supported engine version, run the manual matrix in
[TESTING.md](TESTING.md), especially:

- both center boundaries;
- repeated drag/release cycles;
- project reopen;
- plugin disable/re-enable;
- editor refresh/rescan;
- Android touch behavior;
- no duplicate-signal, camera, or renderer errors.

If internal editor names change, prefer a small version-specific adapter over
broad heuristic tree mutation.
