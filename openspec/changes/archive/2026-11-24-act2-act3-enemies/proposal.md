# Proposal

## Why

Acts 2 (Ice) and 3 (Fire) still reuse Act 1's enemies, pool and forest background. The status toolkit and summoning engine are in place, so the whole enemy roster of both acts, with their bosses, can now be built in one pass instead of four sequential changes (this change merges `act2-ice-enemies`, `act2-boss-krampus`, `act3-fire-enemies` and `act3-boss-fire-dragon`).

## What Changes

- **Act 2 (Ice):** Snow Wolf pups and Alpha (pack bonus, Howl), Ice-Crystal Spider (Web, bite vs slowed), Snow Golem (stored block, Avalanche), Banshee (Brittle, gated Freeze), Yeti (telegraphed Ground Pound, Roar at 50%, slow immunity). 9 battles (3 tier 0, 4 tier 1, 2 tier 2) in a dedicated `battles/map2/` pool, Ice battle background.
- **Krampus** (Act 2 boss): about 90 HP, Freeze-immune, three phases (Birch Switch and Chain Pull; wolf summoning at 50%; telegraphed Winter's Wrath every third action and a Speed Up at 25%). Act 2's tier 3.
- **Act 3 (Fire):** Campfire and Fire Spirits (reusing the half-built `enemies/living_flame/` from PR #39), Fire Salamander (Searing Hide), Fire Imps (Frenzy), Ashen Warrior (Sunder Strike, Rally), Phoenix (ash and revival), Magma Golem (Prepare then Slam with Ashen). 9 battles in `battles/map3/`, Fire battle background.
- **Fire Dragon** (Act 3 boss): about 90 HP, Freeze-immune, three phases (Claw and telegraphed Fire Breath; Roar and imps at 60%; Ember Field and Speed Up at 30%). Act 3's tier 3.
- Engine hook: an enemy can intercept its first death (Phoenix).
- Because everything lands together there is no temporary tier 3 made of Act 1 bosses: the pools go straight to Krampus and the Fire Dragon.
- Placeholder sprites for everything; final art is listed in `art/ART_REQUESTS.md`.

Out of scope: balancing beyond first numbers, final art, new statuses or summoning features.

## Capabilities

### New Capabilities
- `ice-enemies`, `krampus-boss`, `fire-enemies`, `fire-dragon-boss`: see the four spec deltas.

### Modified Capabilities

None.

## Impact

- New: `enemies/` folders per enemy, `battles/map2/` and `battles/map3/`, `art/placeholders/` sprites.
- Code: `scenes/enemy/enemy.gd` (death-intercept hook), `acts/act_2_ice.tres`, `acts/act_3_fire.tres`, `enemies/living_flame/`.
- Tests: new `tools/verify_act_enemies.tscn`.
- Depends on the already applied `combat-status-toolkit` and `enemy-summoning-and-minions`.
- Art: about 15 enemy sprites plus poses (see `art/ART_REQUESTS.md`).
