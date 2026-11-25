# Proposal

## Why

Act 2 needs its own boss. Until now its tier 3 slot holds Act 1's bears and chickens as a stopgap. Krampus is the Ice act's finale: a boss with distinct phases that tests slows, vulnerability and the new summoning system.

## What Changes

- Add the **Krampus** boss (about 90 HP, speed 4, immune to Freeze) with three phases:
  - **Phase 1:** Birch Switch (two quick hits) and Chain Pull (Speed Down plus Brittle).
  - **Phase 2 (at 50% health):** summons up to two Snow Wolves, repeating when they die (with a cooldown).
  - **Phase 3 (at 25% health):** every third action is a telegraphed Winter's Wrath (heavy hit plus a short Freeze) and Krampus speeds up once.
- Add Krampus as Act 2's tier 3 battle and remove the temporary Act 1 bosses from Act 2's pool.
- Placeholder sprite and telegraph pose; final art is listed in `art/ART_REQUESTS.md`.

Out of scope: balancing beyond first numbers, new statuses or engine features, final art.

## Capabilities

### New Capabilities
- `krampus-boss`: Krampus's phases and attacks.

### Modified Capabilities

None.

## Impact

- New: `enemies/krampus/` (stats, AI scene, action scripts), `battles/map2/tier3/tier_3_krampus.*`, placeholder sprites.
- Code: `battles/map2/battle_stats_pool.tres` (replace the temporary tier 3).
- Depends on: `combat-status-toolkit`, `enemy-summoning-and-minions`, and `act2-ice-enemies` (the pool and Snow Wolves).
- Tests: new `tools/verify_krampus.tscn`.
- Art: Krampus sprite with phase 2 and telegraph poses (see `art/ART_REQUESTS.md`).
