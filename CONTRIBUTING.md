# Contributing

Wide Docks is intentionally small. Changes should remain surgical.

## Before changing behavior

Read:

- `docs/ARCHITECTURE.md`
- `docs/COMPATIBILITY.md`
- `docs/TESTING.md`

Then run:

```bash
python scripts/check_release.py
```

## Pull requests

Please include:

- Godot version;
- operating system/device;
- whether the Android editor is involved;
- which dock boundary is affected;
- before/after behavior;
- confirmation that the manual regression matrix was run.

Do not replace the locked v1 sizing/input architecture casually. If a new
Godot version requires a different implementation, isolate the version-specific
difference and preserve the author-facing interaction wherever possible.
