# Changelog

All notable public changes to Wide Docks are documented here.

The project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-09-06

Initial production release.

### Added

- Extended side-dock resizing for narrow and mobile Godot editor layouts.
- Independent left/right center-boundary dragging.
- Native-dragger `gui_input` integration.
- Per-drag visual latching to the actual center-column width.
- Clean plugin disable/restore behavior.
- Upgrade cleanup for development-build metadata.
- Publish-ready documentation and regression checks.
- FDOF Tooling Attribution License 1.0: no game/project credit requirement;
  visible FDOF credit only for redistributed or derivative tooling.

### Production architecture locked

The v1 baseline intentionally avoids editor-control reparenting, global input
interception, `_process()` correction loops, `split_offsets` writes, and a
parallel `InputEventScreenDrag` path.
