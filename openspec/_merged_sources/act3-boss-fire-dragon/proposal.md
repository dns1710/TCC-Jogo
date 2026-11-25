# Proposal

## Why

Act 3 needs its own final boss. Its tier 3 slot holds Act 1's bosses as a stopgap. The Fire Dragon is the game's finale: a multi-phase fight that pulls together burning, telegraphed breath attacks and summoned imps.

## What Changes

- Add the **Fire Dragon** boss (about 90 HP, speed 4, immune to Freeze) with three phases:
  - **Phase 1:** Claw and a telegraphed Fire Breath (heavy hit plus Scorch).
  - **Phase 2 (at 60% health):** summons up to two Fire Imps (with a cooldown) and roars once, giving all allies Attack Up.
  - **Phase 3 (at 30% health):** Ember Field (every action of the Dragon scorches the player) and a one-time Speed Up of 2 stacks.
- Add the Fire Dragon as Act 3's tier 3 battle and remove the temporary Act 1 bosses from Act 3's pool.
- Placeholder sprite and telegraph pose; final art is listed in `art/ART_REQUESTS.md`.

Out of scope: balancing beyond first numbers, new engine features, final art.

## Capabilities

### New Capabilities
- `fire-dragon-boss`: the Fire Dragon's phases and attacks.

### Modified Capabilities

None.

## Impact

- New: `enemies/fire_dragon/`, `battles/map3/tier3/tier_3_fire_dragon.*`, placeholder sprites.
- Code: `battles/map3/battle_stats_pool.tres` (replace the temporary tier 3).
- Depends on: `combat-status-toolkit`, `enemy-summoning-and-minions`, and `act3-fire-enemies` (the pool and Fire Imps).
- Tests: new `tools/verify_fire_dragon.tscn`.
- Art: Fire Dragon sprite with telegraph and later-phase poses (see `art/ART_REQUESTS.md`).
