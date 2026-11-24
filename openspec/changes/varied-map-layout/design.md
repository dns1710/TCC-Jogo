# Design

## Context

`MapGenerator` builds a `FLOORS x MAP_WIDTH` grid of `Room`s (`row` is the floor, `column` the slot) positioned at `(floor * X_DIST, slot * Y_DIST) + offset`, where the offset multiplies a random vector by `PLACEMENT_RANDOMNESS`, currently 0. The map scrolls horizontally, so floors run along x and slots along y. Today it opens three connections from the start to the three floor-1 rooms and, per floor, lets each room link to its own slot plus a 35% chance of each neighbor, rejecting crossings, capped at 3 live rooms (the layout rules that replace this are in the decisions below). That produces three near-straight lanes. Everything outside the generator (`map.gd`, DDA, rerolls, `verify_map_generation`) addresses rooms as `map_data[floor][slot]` and derives camera extents from the constants.

## Goals / Non-Goals

**Goals:**
- Irregular, branching, merging maps with real route choice and an organic look.
- Keep every current structural guarantee.

**Non-Goals:**
- New room types or probabilities, map art, rerolling or DDA rules.

## Decisions

**1. Seven slots.** `MAP_WIDTH = 7` (Slay the Spire uses 7 lanes). It is odd, so `mid = 3` keeps the start and boss in the middle, and `map.gd` and the test already use `MAP_WIDTH / 2`. Lane spacing `Y_DIST` drops from 35 to 20 so the 7 lanes span 120 px (plus jitter) and fit the 144 px screen at the map zoom of 0.9; 16 px room icons still leave a gap. `X_DIST` stays 50.

**2. Route generation instead of per-room nudges.** The start connects to 3 or 4 distinct floor-1 slots chosen at random. Each floor-1 room then walks forward floor by floor to floor 12. After those walks, `routes - starts` extra walks (4 to 6 routes in total) begin from random already active rooms on floors 1 to 8, preferring a target they are not yet connected to, so routes **split** mid-map. A step goes to one of the three neighboring slots with weights 35/30/35 for diagonal, straight, diagonal; landing on an already active room is 1.6 times as likely, so routes **merge**. To keep edges from crossing, each step first computes the allowed target interval from the existing edges of that floor pair: the target must be at least the largest target of any source to the left and at most the smallest target of any source to the right. That interval is never empty, so a walk never gets stuck, and no crossing can occur. All active floor-12 rooms connect to the boss. Every active room lies on a walk that ends at floor 12, so there are no dead ends and every room is reachable by construction.

**3. Validation and bounded regeneration.** After building routes the generator checks the layout rules: 3 to 5 active rooms on floors 1 to 12, no route that stays in one slot, at least 35% of floor 1 to 12 connections change slot, and at least 4 distinct routes (a path-count pass from the start). A map that fails is regenerated, up to 60 attempts, after which the last attempt is kept (the test prints how often retries happen and the final fallback must be zero over 1000 maps per act).

**4. No straight lanes.** The weights in decision 2 make a straight line improbable; the validation in decision 3 removes the rest.

**5. Organic placement with rejection.** `PLACEMENT_RANDOMNESS` becomes a `Vector2` range (20 px along the map, 10 px across), and each room's offset is `(randf - 0.5) * range` per axis. Rooms are placed in order; a candidate offset is rejected when it lands within 14 px of an already placed room, retrying with shrinking amplitude (100%, 75%, 50%, 25%) and finally no jitter. A room with no jitter is at least 20 - 5 = 15 px from any neighbor because neighbor offsets across the map are at most 5 px, so the minimum distance always holds. Lines already connect `room.position`s, so they follow the jitter. Jitter is applied to every room's data position, active or not.

**6. Lines are checked on the real positions.** Slot order alone does not guarantee a clean drawing: jitter and steep lines can make lines pass through or lie over each other. After placing rooms the generator checks the drawn segments: no two segments without a shared room intersect, no segment passes within 8 px of an unrelated room, and two segments that share a room leave it at least 12 degrees apart. If a placement fails the check it is retried with a smaller amplitude, down to no jitter, which always passes. To make that true on the grid, the start and the boss are pushed 30 px further out (`FRAME_GAP`), the start only fans out to the 5 inner lanes and the floor before the boss only uses those 5 lanes, so the lines out of the start and into the boss have gentle, well separated angles (about 14 degrees apart or more). `map.gd` extends its camera clamp by the same gap, and saved 3-slot maps still open because the start room is taken from the loaded map's own width.

**7. Test update.** `verify_map_generation` is updated in the same change.

## Risks / Trade-offs

- [More route choice shifts game balance (more shops or campfires reachable)] → Keep room type rolls untouched; the map has more rooms per floor (3 to 5 against at most 3), but a run still walks one room per floor, so the room types a run sees stay governed by the same rolls; compare room-type counts over 1000 maps before and after in the test output.
- [Line crossings or overlaps from jitter] → The placement check in decision 6 runs on the real segments, and `verify_map_generation` repeats it independently over 1000 maps per act (it fails when the check is disabled: lines out of the start were as little as 6 degrees apart).
- [Map taller than the screen or hidden under the top bar] → 7 lanes at 20 px = 120 px plus jitter at zoom 0.9 fit; verify by screenshot, including the camera clamp in `map.gd`, and adjust `Y_DIST` or the zoom if the top lane is covered.
- [Rejection and regeneration loops] → Bounded attempts, test over 1000 maps per act confirms no failure.
- [Old saves with 3-slot maps] → A saved map is loaded as data with its own rows, so a continued run keeps its current map; only new maps use 7 slots. The test loads a saved 3-slot map to confirm.
