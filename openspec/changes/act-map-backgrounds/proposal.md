# Proposal

## Why

The map screen sits on a gradient from grey to brown (a `GradientTexture1D` in `map.tscn`), which looks flat and ugly next to the rest of the game. `Act.background` and `Map.set_act` already support a per-act map background, but no act sets one, so every act shows the brown gradient.

## What Changes

- Each act gives the map a background: the forest for Act 1, the ice scene for Act 2 and the fire scene for Act 3, reusing the existing battle artwork, darkened so rooms, lines and the top bar stay readable.
- The default when an act defines no map background becomes the same darkened forest, never the brown gradient. The gradient is removed.
- The background stays fixed behind the scrolling map and is scaled to fill the 256x144 screen.

Out of scope: dedicated map artwork (the art developer can supply it later by setting `Act.background`), map layout (see `varied-map-layout`), room and line icons.

## Capabilities

### New Capabilities
- `map-backgrounds`: which background the map uses and its readability.

### Modified Capabilities

None.

## Impact

- Edited: `scenes/map/map.tscn` (background node replaces the gradient texture), `scenes/map/map.gd` (`set_act` scaling and a default), `acts/act_1_forest.tres`, `act_2_ice.tres`, `act_3_fire.tres` (set `background`).
- Tests: extend `tools/verify_act_framework.gd` or add `tools/verify_map_background.tscn`.
