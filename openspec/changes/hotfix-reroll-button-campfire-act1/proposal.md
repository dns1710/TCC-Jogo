## Why

Playtesting on the `post-playtest-hotfix` branch found two problems. After the player reaches 0 rerolls and then gains one from an event (e.g. Fallen Adventurer, Forest Guardian), the map's Reroll button stays disabled, so the reward cannot be used. Separately, the Campfire enemy (Living Flame) is a fire enemy in Act 3 but is meant to appear in Act 1 (Forest).

## What Changes

- The Reroll button's enabled state is refreshed whenever the map is shown, and whenever the reroll count changes outside the map (events), so it reflects `run_stats.rerolls`.
- The Campfire battle (`tier_2_campfire`) is moved from the Act 3 (fire) battle pool to the Act 1 (forest) battle pool, changing its tier from 1 to 2.
- Verification script `tools/verify_act_enemies.gd` is updated so the Act 3 pool no longer expects Campfire and Act 1 allows it.

Out of scope: rebalancing Campfire stats/gold, reworking the reroll feature, the unused `scenes/run/reroll_ui.gd` (it reads gold, not rerolls, and appears unwired).

## Capabilities

### New Capabilities
- `map-reroll`: Rerolling map rooms and the Reroll button's availability.
- `act-battle-pools`: Which enemy battles can appear in each act.

### Modified Capabilities

## Impact

- `scenes/map/map.gd` (button refresh), possibly `custom_resources/run_stats.gd` (signal for reroll changes) and `custom_resources/events/event_outcome.gd`.
- `battles/battle_stats_pool.tres` (Act 1), `battles/map3/battle_stats_pool.tres` (Act 3), `battles/map3/tier2/tier_2_campfire.*` (moved to `battles/map1/tier2/`).
- `tools/verify_act_enemies.gd`.
