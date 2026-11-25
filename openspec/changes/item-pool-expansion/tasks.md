# Tasks

## 1. Art direction and pipeline

- [x] 1.1 Extract the colour palette of every existing icon under `art/verdadeira arte/items/` and `art/verdadeira arte/status/` with a headless Godot script, and record the palette (hex list, 3-tone ramps per material) in `art/ART_DIRECTION.md`; verify the file lists at least 20 colours and the script output matches
- [x] 1.2 Write the rest of `art/ART_DIRECTION.md` from design D8 (light source, selective outline, rarity language, status shape coding, greyscale test, review checklist) and verify every checklist item is phrased as a pass/fail check
- [x] 1.3 Add `tools/build_icons.gd` and `tools/build_icons.tscn`: read text pixel maps from `art/src/items/` and `art/src/statuses/` (one char per pixel, legend into the shared palette), write PNGs, reject wrong sizes or unknown legend chars; verify with a sample 16x16 and 10x10 map that the PNGs are produced and a malformed map fails with a clear message
- [x] 1.4 Add a contact-sheet scene `tools/icon_review.tscn` that shows every new icon at native size and at 4x on the inventory, relic bar, shop and each act background; verify it opens headless-free in the editor and renders the sample icons from 1.3
- [x] 1.5 Add `tools/verify_item_art.gd` (size, transparency, palette membership, no duplicates or pure palette swaps, no placeholder paths on statuses) and wire it into `tools/run_suite.ps1`; verify it fails on a deliberately wrong sample and passes on a good one

## 2. Status art (6 icons)

- [x] 2.1 Draw Freeze, Brittle, Sunder, Scorch, Ashen and Ward as 10x10 pixel maps following D8 shape coding; verify each passes the greyscale shape test in the contact sheet
- [x] 2.2 Build the PNGs into `art/verdadeira arte/status/` with import files, review in the contact sheet in a single row next to Burn, Poison and Speed Down, and record the review result in `art/ART_DIRECTION.md`; verify the six are distinguishable by shape alone
- [x] 2.3 Point `status_freeze`, `status_brittle`, `status_sunder`, `status_scorch` and `status_ashen` `.tres` files at the new icons and verify `tools/verify_item_art.gd` reports no placeholder paths

## 3. Engine hooks (A, B, C)

- [x] 3.1 Add `status_added`, `status_removed` and `status_absorbed` signals and `remove_status(id)` to `StatusHandler`, forward them through `Events`, and extend `tools/verify_combat_statuses.gd` to cover add, remove, remove-missing and no-event-when-negated
- [x] 3.2 Add `Events.player_attacked(targets, damage)` emitted after `on_attack_hit` in `action_attack.gd` and verify with a test that an existing weapon (Poison Dagger) still behaves identically and a subscribed test relic sees one event per attack
- [x] 3.3 Add `slow_immune`, `before_death` and `next_atb_start` to `Player`, apply them in `take_damage` and `reset_atb`, and verify with tests: slow immunity ignores Speed Down, a veto keeps the player alive without a death event, carry-over applies once and caps at 100%
- [x] 3.4 Run the existing `tools/run_suite.ps1` and verify no existing verify script regresses

## 4. Ward status

- [x] 4.1 Add `statuses/status_ward.gd` and `status_ward.tres` (no stacking, no expiry, tooltip text) with the debuff id list and interception in `add_status`; verify with tests for Freeze, Brittle, Sunder, Scorch, Ashen, Speed Down, Attack Down, Poison and Burn absorbed, buffs not absorbed, one debuff per Ward, and the absorbed event fired once
- [x] 4.2 Verify Ward through both application routes (`StatusEffect` and direct `add_status` from an enemy action) and that Ward does not carry into the next combat
- [x] 4.3 Assign the Ward icon and confirm it appears in the status row with the correct tooltip in a battle scene

## 5. Items: commons and uncommons (10 items)

- [x] 5.1 Draw the 10 item icons (Kindling Bundle, Pine-Tar Gloves, Fur-Lined Cap, Breaker Pick, Riposte Foil, Frostborn Circlet, Warding Talisman, Emberweave Tunic, Rime Bead, Hunter's Snare) from the D9 briefs, build the PNGs, and verify each passes the review checklist in the contact sheet on all three act backgrounds
- [x] 5.2 Implement the 10 item scripts and `.tres` resources (slot, rarity, stats, tooltip text) with signal connect/disconnect in `activate_relic`/`deactivate_relic`; verify each with a scenario test taken from the item-catalog-expansion spec
- [x] 5.3 Verify two combats back to back with all 10 equipped produce no double triggers and no leaked signals

## 6. Items: rares (8 items)

- [x] 6.1 Draw the 8 rare icons (Shatterglass Hammer, Cinderbrand, Bulwark Maul, Cracked Visor, Sentinel's Aegis, Carrion Thurible, Quicksilver Spurs, Reactive Plate) with the rare glow/rim-light cue, build, and verify checklist pass and a visible rarity step over the uncommons in the contact sheet
- [x] 6.2 Implement the 8 item scripts and resources; verify with scenario tests including Shatterglass boss fallback, Cinderbrand detonation, Bulwark Maul cap, Reactive Plate block-break detection and Thurible spread
- [x] 6.3 Verify the extra-hit ordering (status applied after bonus damage) for Shatterglass and Rime Bead does not consume the status it just applied

## 7. Items: mythics (6 items)

- [x] 7.1 Draw the 6 mythic icons (Mirrorscale Mail, Phoenix Feather, Hunter's Mercy, Frostfire Pike, Glass Heart, Warden's Visage) with the mythic-only motif, do a second review pass for the hand-made feel, and verify no mythic can be mistaken for a rare at native size
- [x] 7.2 Implement the 6 item scripts and resources; verify with scenario tests including Phoenix Feather once per combat and reset, Hunter's Mercy execute and boss branch, Frostfire Pike alternation and thermal shock, Glass Heart loop, Mirrorscale reflect, Warden's Visage +1 stack
- [x] 7.3 Verify Mirrorscale Mail never mirrors a status onto a target that cannot receive it (freeze-immune boss, slow-immune enemy)

## 8. Drop pools and integration

- [x] 8.1 Add all 24 items to `battle_relic_pool` in `run.tscn`, `treasure_relic_pool` in `treasure.tscn` and `shop_relics` in `shop.tscn`; extend `tools/verify_item_pools.gd` so every new item is in the right pools and the counts are 15/21/19/8
- [x] 8.2 Verify chests still never offer commons and that tier-2 rewards never offer commons with the larger pool
- [x] 8.3 Check every tooltip against its resource and code values with a verify script that parses stats and dice numbers from the text
- [ ] 8.4 Play one full run per act with a mixed loadout and record in `art/ART_DIRECTION.md` any icon that read poorly in play, then revise and re-review those icons

## 9. Dice instead of percentages

- [x] 9.1 Make Brittle add one extra die of the hit's size (`DamageEffect.die_sides`, `brittle_next_hit` on Player and Enemy, every attack action reporting its die) and verify `verify_combat_statuses` and `verify_item_pool_expansion` cover the d6 hit, the flat hit, the no-modifier hit and the weapon attack
- [x] 9.2 Convert Bulwark Maul (1d4 per 5 block, max 3d4) and Hunter's Mercy boss branch (extra weapon die), update tooltips and specs, and verify `verify_item_pools` checks the new tooltip text against the item

## 10. Playtest tweaks

- [x] 10.1 Phoenix Feather is single use (removed from the inventory when it triggers, still in the pools) and applies 1 Scorch; Carrion Thurible passes statuses to 1 random enemy; verify with `verify_item_pool_expansion`
- [x] 10.2 Floating combat text cascades per actor (`PopUp` lanes) and verify with `tools/verify_popup_cascade.tscn`

## Workflow follow-up

- Review the rarity assignments against the design table before merging, since rarity feeds the difficulty score.
- Archive the change after review requirements are satisfied and verify the archived result.
