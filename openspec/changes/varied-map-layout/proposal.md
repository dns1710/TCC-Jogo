# Proposal

## Why

Every map is three straight horizontal lanes: 3 slots per floor, positions on an exact grid (`PLACEMENT_RANDOMNESS = 0`), and a generator that mostly lets a room connect to the room straight ahead. Runs feel identical and there is little route choice. The goal is a Slay the Spire style map, as organic as the screen allows: many routes that branch and merge, partly filled floors, rooms that are not on a grid, and no route that is just a straight line.

## What Changes

- Widen the map from 3 to **7 slots** per floor (odd, so the start and boss stay in the middle slot) and generate **routes** instead of per-room column nudges: the start fans out to 3 or 4 rooms and 4 to 6 routes in total walk to the boss, splitting from existing rooms, merging into existing rooms, and shifting slot, never crossing.
- Floors are only partly filled (3 to 5 of the 7 slots active on floors 1 to 12), so the map has an irregular silhouette instead of full rows.
- Offset each room from its grid slot by a random amount (up to about 10 px along the map and 5 px across, `PLACEMENT_RANDOMNESS`), with rejection so rooms never touch; lanes are packed tighter (20 px) so 7 lanes fit the 144 px screen.
- All existing guarantees stay: reachability, no dead ends, no crossings, one boss on floor 13 in the middle slot, start room, treasure floor and pre-boss campfire floor, protected first and last floors.
- Update the map generation test to the new width and add checks for the new properties.

Out of scope: room type probabilities, room art, map background (separate change `act-map-backgrounds`), rerolling and difficulty conversion rules.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `map-generation`: slot count per floor changes from 3 to 7; adds branching and merging routes, partly filled floors, no straight-lane routes, and organic room placement.

## Impact

- Code: `scenes/map/map_generator.gd` (constants, route generation, placement), possibly `scenes/map/map.gd` (camera extent uses `MAP_WIDTH` and `Y_DIST`, already derived from the constants).
- Tests: `tools/verify_map_generation.gd` (`EXPECTED_WIDTH` 3 to 7, new property checks); `verify_dda` and `verify_act_flow` must still pass.
