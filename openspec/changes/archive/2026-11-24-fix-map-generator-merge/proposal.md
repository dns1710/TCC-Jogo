# Proposal

## Why

The project does not compile. Merge `1ef1318` combined two incompatible map generators (a single-region 14-floor map and a two-region 13+13-floor map), leaving `FLOORS_PER_REGION` undefined and `treasure_floor` declared twice. The parse error in `map_generator.gd` cascades into `map.gd` and `run.gd`, so the game cannot start. `main` has the same break, and every other planned feature is blocked until it is fixed.

## What Changes

- Restore the single-region, 14-floor map generator (the `c5a54c6` shape) and remove the half-merged two-region code from `map_generator.gd`.
- Remove the `FLOORS_PER_REGION` references from `map.gd`; protected floors (not rerollable, not convertible by DDA room changes) become the first and last floor only.
- Delete the 14 editor-autosave `*.tmp` files tracked in git and add `*.tmp` to `.gitignore`.
- Add a headless verification scene that generates 1000 maps and asserts the map invariants, and record those invariants as the first `map-generation` spec.

Out of scope: any act, region or per-act map work, and any change to `PLACEMENT_RANDOMNESS`. The map layout, room mix and floor count stay as in `c5a54c6`.

## Capabilities

### New Capabilities
- `map-generation`: the shape and guarantees of a generated run map (floor count, connectivity, non-crossing paths, single boss, fixed room floors, protected floors).

### Modified Capabilities

None. `openspec/specs/` is empty, so there is nothing to modify.

## Impact

- Code: `scenes/map/map_generator.gd`, `scenes/map/map.gd` (`_is_protected_floor`). `scenes/run/run.gd` needs no edit; it only recovers once `MapGenerator` compiles.
- New: a headless verification scene and script under `tools/`.
- Repo hygiene: 14 tracked `*.tmp` files removed, `.gitignore` updated.
- Tooling: verified with Godot 4.6.2 headless; no new dependencies.
