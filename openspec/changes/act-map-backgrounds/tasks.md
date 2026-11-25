# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import. Screenshots: temporary scene in `tools/` run non-headless, deleted afterwards.

## 1. Test first

- [ ] 1.1 Add a check (in `verify_act_framework` or `tools/verify_map_background.tscn`): each act has a non-null `background`, `Map.set_act` applies it, an act with none falls back to the forest texture, and the scene no longer contains a `GradientTexture1D`. Verify: it fails on the current code.

## 2. Implementation

- [ ] 2.1 Set `Act.background` on the three act resources to the forest, ice and fire images. Verify: the harness passes the per-act check.
- [ ] 2.2 Replace the gradient in `map.tscn` with a covered, darkened `TextureRect` defaulting to the forest, fix its size in `set_act` if needed. Verify: harness fallback check passes and the background fills 256x144.
- [ ] 2.3 Tune darkening or add a vignette per readability. Verify: rendered map screenshots of all three acts show rooms and lines clearly distinguishable.

## 3. Integration

- [ ] 3.1 Boot check and all suites. Verify: no script errors and every suite exits 0.
- [ ] 3.2 Manual look at the map in each act while scrolling. Left to the user.

## Workflow follow-up

- Archive after review so `map-backgrounds` becomes a main spec.
