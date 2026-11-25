# Proposal

## Why

Act 2 (Ice) currently reuses Act 1's enemies, pool and forest background. It needs its own roster of enemies with real mechanics (not HP sponges) that use the new statuses, and its own battle pool so every Act 2 fight, elite and DDA-upgraded battle draws from Ice content.

## What Changes

- Add five Ice enemies, each built around a mechanic:
  - **Snow Wolf pups and Alpha:** a pack that hits harder the more wolves are alive; the Alpha's Howl speeds the pack up.
  - **Ice-Crystal Spider:** Web slows you, and Crystal Bite hits harder against a slowed target.
  - **Snow Golem:** builds block every action and releases it as an Avalanche at the cap.
  - **Banshee:** a controller that makes your next hit costly (Brittle) and can briefly Freeze you.
  - **Yeti:** a telegraphed Ground Pound, and below half health it roars and becomes slow-immune with more attack.
- Add Act 2 battles (3 tier 0, 4 tier 1, 2 tier 2) and a dedicated battle pool with its own resource; point Act 2 at it and at the Ice battle background.
- Until Krampus lands (`act2-boss-krampus`), Act 2's tier 3 holds Act 1's bosses so the boss floor never has an empty battle.
- Ship with placeholder sprites; list the final art in `art/ART_REQUESTS.md`.

Out of scope: the Krampus boss, final art, balancing beyond first numbers, new statuses or summoning (provided by the two prerequisite changes).

## Capabilities

### New Capabilities
- `ice-enemies`: the behavior of each Ice enemy and the composition of Act 2's battle pool.

### Modified Capabilities

None.

## Impact

- New: `enemies/snow_wolf/`, `snow_wolf_alpha/`, `ice_spider/`, `snow_golem/`, `banshee/`, `yeti/` (stats, AI scenes, action scripts), `battles/map2/` (battles and pool), `art/placeholders/` sprites.
- Code: `acts/act_2_ice.tres` (pool and battle background).
- Depends on: `combat-status-toolkit` (Freeze, Brittle) and `enemy-summoning-and-minions` (telegraph, threshold and the act battle background).
- Tests: new `tools/verify_ice_enemies.tscn`.
- Art: 6 enemy sprites plus variants (see `art/ART_REQUESTS.md`).
