# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import.

## 1. Test harness

- [x] 1.1 Add `tools/verify_act_enemies.tscn` and script: content validation (every enemy loads with positive stats and an AI with actions), both pools (tier counts 3/4/2/1, tier 0 to 2 only act enemies, tier 3 only the act's boss, no empty tier), mechanic tests for every scenario in the four specs, and a smoke run of every Act 2 and Act 3 battle in the real battle scene with a stand-in player. Verify: it fails before the content exists and passes after.

## 2. Shared pieces

- [x] 2.1 Placeholder sprites (recolored copies) for all enemies and poses into `art/placeholders/`. Verify: each file exists and loads, names match `art/ART_REQUESTS.md`.
- [x] 2.2 Engine hook: `Enemy.before_death` so an enemy script can veto a lethal hit. Verify: a vetoing enemy survives the first lethal hit and dies on the second; existing enemies die as before.

## 3. Act 2 enemies

- [x] 3.1 Snow Wolf pup and Alpha (pack bonus, Howl limit). Verify: +1 damage per other wolf, no second Howl within 4 actions.
- [x] 3.2 Ice-Crystal Spider. Verify: bite damage x1.5 against a slowed target.
- [x] 3.3 Snow Golem. Verify: five Pack Snow actions reach 20 block, then Avalanche leaves block at 0.
- [x] 3.4 Banshee. Verify: no Wail without Brittle, none within 5 actions, no Freeze on a frozen or immune player.
- [x] 3.5 Yeti. Verify: Roar is next after crossing 50% and Speed Down then has no effect.
- [x] 3.6 Act 2 battles and `battles/map2/` pool, Act 2 pointed at the pool and the Ice background. Verify: pool test passes.

## 4. Krampus

- [x] 4.1 Krampus stats (Freeze-immune) and phase 1 (Birch Switch, Chain Pull). Verify: two hits per Switch; 3 Speed Down and Brittle from Chain Pull.
- [x] 4.2 Phase 2 (50% threshold, wolf summons, cap 2, 3-action cooldown). Verify: 2 wolves at the threshold, none while 2 alive, resummon after the cooldown.
- [x] 4.3 Phase 3 (25% threshold with Speed Up once, Winter's Wrath every third action with telegraph and Freeze). Verify: warning precedes the strike, cadence of three, one big hit crosses both thresholds.
- [x] 4.4 Krampus tier 3 battle in the Act 2 pool. Verify: tier 3 contains only Krampus.

## 5. Act 3 enemies

- [x] 5.1 Campfire and Fire Spirits in `enemies/living_flame/` (adopt design stats, remove the one-shot flag, Stoke, spawn rule, bound fizzle). Verify: spawn cadence, healing clamp, Burn on the player, fizzle ends the battle.
- [x] 5.2 Fire Salamander (Searing Hide, 3-action cycle). Verify: Scorch only while the hide is up.
- [x] 5.3 Fire Imp (Frenzy). Verify: one of three dies, the others get one Speed Up each, capped at 3.
- [x] 5.4 Ashen Warrior. Verify: Sunder after the strike; Rally never without an ally or within 4 actions.
- [x] 5.5 Phoenix (ash pile, revival at 60% after 6 seconds, no second rebirth). Verify: revival, killing the ash, second death.
- [x] 5.6 Magma Golem. Verify: Prepare adds 8 block and warns, then Slam applies Ashen.
- [x] 5.7 Act 3 battles and `battles/map3/` pool, Act 3 pointed at the pool and the Fire background. Verify: pool test passes.

## 6. Fire Dragon

- [x] 6.1 Dragon stats (Freeze-immune) and phase 1 (Claw, telegraphed Fire Breath with Scorch x2). Verify: warning precedes the Breath, 2 Scorch applied.
- [x] 6.2 Phase 2 (60% threshold, Roar once, imp summons cap 2, 4-action cooldown). Verify: one Roar, at most 2 imps, resummon after the cooldown.
- [x] 6.3 Phase 3 (30% threshold, Speed Up x2 once, Ember Field). Verify: 1 Scorch per Dragon action, Speed Up once, one hit across both thresholds works.
- [x] 6.4 Dragon tier 3 battle in the Act 3 pool. Verify: tier 3 contains only the Dragon.

## 7. Integration

- [x] 7.1 Boot check and all suites; view rendered battles of both acts. Verify: no script errors, every suite exits 0, backgrounds and placeholder enemies look right.
- [ ] 7.2 Hands-on: win a fight of each act and each boss. Verify (manual playtest, left to the user).

## Workflow follow-up

- Archive after review so the four capabilities become main specs. The four original changes are kept in `openspec/_merged_sources/`.
