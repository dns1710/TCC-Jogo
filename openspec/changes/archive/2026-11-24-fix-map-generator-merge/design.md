# Design

## Context

`map_generator.gd` at HEAD is `c5a54c6`'s single-region generator with Daniel's two-region `_generate_region` code pasted in (merge `1ef1318`). It declares `treasure_floor` twice, uses an undefined `FLOORS_PER_REGION`, and mixes region-relative and absolute floor indices. `map.gd` references `FLOORS_PER_REGION` only in `_is_protected_floor`. Everything else in `map.gd` and `run.gd` already uses `MapGenerator.FLOORS`, which is still 14, so the single-region shape is what the rest of the code expects (see proposal.md for motivation).

Constraints found while investigating:
- Scripts that use autoloads (`RNG`, `Events`, `SFXPlayer`, `Shaker`) do not compile under `godot --script`, so a verification script cannot run in that mode; it must run as a scene.
- `main` carries the same broken generator, so the fix must be a forward commit, not a revert of this branch.

## Goals / Non-Goals

**Goals:**
- A compiling project whose generator behaves as `c5a54c6` did, with its guarantees written down and checked automatically.
- A repeatable headless check that future map work (acts, layout randomness) can reuse.

**Non-Goals:**
- Per-act maps, act parameters, per-act pools or backgrounds.
- Changing `PLACEMENT_RANDOMNESS`, floor count, room-type odds or tier assignment.
- Reverting `map.gd` wholesale to `c5a54c6`; its other post-baseline changes stay.

## Decisions

**1. Restore `generate_map()` from `c5a54c6` instead of patching the merged file.** The merged file has no correct region-relative logic to salvage, and patching leaves two code shapes to reason about. The baseline is known to parse and its logic is small. Alternative considered: finish the two-region version (drop-in `FLOORS_PER_REGION`/`REGION_COUNT`, make type distribution region-relative). Rejected: the planned work is three acts with their own boss, pools and background, which per-act maps serve better than one long map, and the two-region code would be thrown away.

**2. Keep `map.gd` and edit only `_is_protected_floor`.** It becomes `row == 0 or row == MapGenerator.FLOORS - 1`. Reverting `map.gd` would drop unrelated improvements from the same merge.

**3. Verify with a scene, not a script.** Add `tools/verify_map_generation.tscn` plus its script. It instantiates a `MapGenerator` with the project's `battle_stats_pool.tres` and `event_room_pool.tres`, calls `setup()` once and `generate_map()` 1000 times, asserts the spec invariants, prints a one-line summary, and calls `get_tree().quit(1)` on any failure (0 on success). Run as `Godot --headless --path . res://tools/verify_map_generation.tscn`. Alternative: `--script`; rejected because of the autoload limitation above.

**4. Delete tracked `*.tmp` files and ignore the pattern.** `git rm` the 14 autosave files and add `*.tmp` to `.gitignore`. Confirm none is referenced by any scene first.

## Risks / Trade-offs

- [The 1000-run check misses a rare shape] → It checks structural invariants on each map rather than comparing to a fixture, so any generated shape is covered; raise the count if a rare failure ever shows.
- [Restoring from `c5a54c6` loses a generator change from the merge that someone wanted] → The generator at HEAD equals `main`'s, and its only post-baseline additions are the region code; diff HEAD against `c5a54c6` before overwriting and confirm only that code is lost.
- [The verification scene is the first thing under `tools/`] → Keep it self-contained so it can be deleted or moved without touching game code.
