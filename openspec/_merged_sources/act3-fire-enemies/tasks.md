# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Requires `combat-status-toolkit` and `enemy-summoning-and-minions` applied. Run checks after a headless import.

## 1. Test harness first

- [ ] 1.1 Add `tools/verify_fire_enemies.tscn` and script: content validation (every enemy loads with positive stats and an AI with actions), the Act 3 pool (tier counts 3/4/2/1, tier 0 to 2 only Fire enemies, no empty tier), mechanic tests for every scenario in the `fire-enemies` spec, and a smoke run of every Act 3 battle in the real battle scene for 20 seconds with a stand-in player. Verify: it exits 1 on the current code.

## 2. Placeholder sprites

- [ ] 2.1 Generate recolored placeholder sprites for the 7 enemies (plus ash pile and Golem prepare variants) into `art/placeholders/`. Verify: each file exists and loads, and names match `art/ART_REQUESTS.md`.

## 3. Engine hook

- [ ] 3.1 Add the `before_death` hook to `Enemy` so an enemy script can veto a lethal hit. Verify: a test enemy that vetoes once survives the first lethal hit and dies on the second; existing enemies die as before.

## 4. Enemies

- [ ] 4.1 Campfire and Fire Spirits in the existing `enemies/living_flame/` (adopt design stats, remove the one-shot flag from the burn attack, implement `campfire_heal.gd` as Stoke, add the Campfire AI scene; spawn rule, Stoke, Burn on hit, bound fizzle). Verify: the harness covers the spawn cadence, healing clamp, Burn on the player and fizzle ending the battle.
- [ ] 4.2 Fire Salamander (Searing Hide with the 3-action cycle). Verify: damage scorches the player with the hide up and not after its third action until it acts again.
- [ ] 4.3 Fire Imp (Frenzy). Verify: killing one of three imps gives the others one Speed Up each, capped at 3.
- [ ] 4.4 Ashen Warrior (Sunder Strike, gated Rally). Verify: Sunder applied after the strike, Rally never without an ally or within 4 actions.
- [ ] 4.5 Phoenix (ash pile, 6 second revival at 60%, no second rebirth). Verify: the harness covers revival, killing the ash, and the second death.
- [ ] 4.6 Magma Golem (15 block, Prepare then Slam with Ashen, Cinder Punch). Verify: Prepare adds 8 block and shows a warning, the Slam follows and applies Ashen.

## 5. Act 3 content

- [ ] 5.1 Build the 9 Act 3 battles with `BattleStats` (gold per tier as Act 1) and `battles/map3/battle_stats_pool.tres` with Act 1's two bosses as temporary tier 3. Verify: the pool test passes.
- [ ] 5.2 Point `acts/act_3_fire.tres` at the new pool and the Fire battle background. Verify: `verify_act_flow` passes and a rendered Act 3 battle shows the Fire background and a placeholder enemy.

## 6. Integration

- [ ] 6.1 Boot check and all suites, then play two Act 3 fights of different tiers. Verify: no script errors, every suite exits 0, and each fight can be won.

## Workflow follow-up

- Archive the change after review so `fire-enemies` becomes a main spec.
