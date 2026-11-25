# Proposal

## Why

Act 3 (Fire) reuses Act 1's enemies, pool and forest background. It needs its own roster built around burning, block-breaking and enemies that change the shape of the fight (a campfire that spawns and heals spirits, a phoenix that comes back), plus its own battle pool.

## What Changes

- Add six Fire enemies, each built around a mechanic:
  - **Campfire and Fire Spirits:** the Campfire (no attack) spawns up to 2 Spirits that burn you and heals them; kill the Campfire and the Spirits fizzle.
  - **Fire Salamander:** Searing Hide scorches whoever hits it, but the hide drops every third action.
  - **Fire Imps:** fast and fragile; each imp that dies speeds up the survivors.
  - **Ashen Warrior:** a commander whose Sunder Strike makes your next hit ignore block and whose Rally buffs allies.
  - **Phoenix:** at 0 health it becomes a small ash pile and revives after 6 seconds unless that pile is killed.
  - **Magma Golem:** slow and armored; restokes block while telegraphing a Slam that applies Ashen.
- Add a small engine hook for the Phoenix: an enemy can intercept its first death.
- Add Act 3 battles (3 tier 0, 4 tier 1, 2 tier 2) and a dedicated battle pool; point Act 3 at it and at the Fire battle background.
- Until the Fire Dragon lands (`act3-boss-fire-dragon`), Act 3's tier 3 holds Act 1's bosses so the boss floor is never empty.
- Ship with placeholder sprites; final art is listed in `art/ART_REQUESTS.md`.

Out of scope: the Fire Dragon boss, final art, balancing beyond first numbers, new statuses and summoning (provided by the prerequisite changes).

## Capabilities

### New Capabilities
- `fire-enemies`: the behavior of each Fire enemy and the composition of Act 3's battle pool.

### Modified Capabilities

None.

## Impact

- New: `enemies/living_flame/` (existing half-built Campfire and Flames from PR #39, completed and renamed in place: Flames = Fire Spirit), `fire_salamander/`, `fire_imp/`, `ashen_warrior/`, `phoenix/`, `magma_golem/`, `battles/map3/`, `art/placeholders/` sprites.
- Code: `scenes/enemy/enemy.gd` (death-intercept hook), `acts/act_3_fire.tres` (pool and battle background).
- Depends on: `combat-status-toolkit` (Scorch, Ashen, Sunder) and `enemy-summoning-and-minions` (spawn, fizzle, heal, telegraph).
- Tests: new `tools/verify_fire_enemies.tscn`.
- Art: 7 enemy sprites plus variants (see `art/ART_REQUESTS.md`).
