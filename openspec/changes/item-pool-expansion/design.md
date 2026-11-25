# Design

## Context

Items are `Relic` resources (`custom_resources/relic.gd`) with a slot (`Equip`), a rarity, flat stat bonuses and an optional script. A script reacts through `activate_relic` (called by relic type: start of combat, start/end of turn, end of combat, event-based), `get_weapon_bonus_damage` and `on_attack_hit`. The last two are only called on the equipped weapon (`action_attack.gd`). Statuses are `Status` resources added through `StatusHandler.add_status`, which has no interception point, no removal helper and no signal. Block and attack are the only player actions and `Events.action_used` already tells them apart. Enemies already expose `before_death` and `slow_immune`; the player does not.

Drops roll a rarity (weights differ per source), then pick uniformly within it. Rarity also feeds the difficulty score (1/3/5/8). Item icons are 16x16 and status icons 10x10 in `art/verdadeira arte/`; the project renders at 256x144 with nearest filtering. Freeze, Brittle, Ashen, Scorch and Sunder still ship placeholder icons from `art/arte nao tao verdadeira/`.

## Goals / Non-Goals

**Goals:**
- Give every item behaviour that uses the statuses, with the smallest engine surface that supports all 24.
- Ship art that is clearly better than placeholder quality and consistent across 30 new or replaced icons.
- Keep every item verifiable headlessly, in the style of the existing `tools/verify_*` scripts.

**Non-Goals:**
- Act-weighted pools, rebalancing existing items, new enemies, a second new status.
- A new item UI, new rarity tiers or changed drop weights.

## Decisions

### D1. One new status (Ward), implemented as an interception, not a modifier
`add_status` checks the owner for Ward before adding any debuff. Debuffs are identified by an explicit list of status ids kept next to the check, not by a flag on every status resource, because buffs and debuffs share the same base class and the list is short and stable.
Alternatives: a `is_debuff` export on `Status` (touches 15 resources and invites mistakes); a damage-style modifier (Ward has nothing to do with damage).
Ward has `StackType.NONE` and never expires (`can_expire = false`), so a second Ward is ignored by the existing "already present" branch.

### D2. Hook A: signals on `StatusHandler`, forwarded to `Events`
`StatusHandler` emits `status_added(status)` and `status_removed(status)`; it also emits a `status_absorbed(status)` when Ward negates something. `Events` re-emits them with the owner so items subscribe once. `remove_status(id)` frees the status UI, which also runs the status cleanup path already used when stacks reach 0. Cinderbrand and Glass Heart need removal; Mirrorscale needs the absorbed signal.
Alternative: items poll status handlers each turn. Rejected: it misses short-lived statuses (Brittle lasts one hit) and is racy with the 0.25s status apply tween.

### D3. Hook B: `Events.player_attacked(targets, damage)` from the attack action
Emitted after damage and after the weapon's `on_attack_hit`, so existing weapons are untouched and ordering is deterministic. Non-weapon items subscribe in `activate_relic` and disconnect in `deactivate_relic`, following the pattern in `berserker_helmet.gd`. Extra damage dealt by items goes through `DamageEffect` as a separate hit; this means each extra hit can consume Brittle or Sunder, which is intended and noted in tooltips where relevant.
Alternative: widen `on_attack_hit` to every equipped relic. Rejected: it changes a contract every weapon depends on.

### D4. Hook C: three small player additions
- `slow_immune` as a plain variable on `Player` (`SpeedDownStatus` already reads `target.get("slow_immune")`).
- `before_death: Callable` on `Player`, checked in the `take_damage` finished callback exactly as `Enemy` does. The callable restores health itself and returns true to veto.
- `next_atb_start: float` on `Player`, consumed inside `reset_atb()` (which `ATBManager` calls on `player_action_completed`). Items set it during the action; `reset_atb` then applies it and clears it. This avoids ordering races with the signal that triggers the reset.
Alternative: items write `player.atb` directly. Rejected: the reset runs after the action and wipes it.

### D5. Item behaviours that need counters keep state in the relic instance and reset on `activate_relic`
Existing items (Stick, Lighter) already do this. Each combat's start calls `activate_relic`, which resets counters and reconnects signals. The resources are shared between runs, so every item that subscribes to an `Events` signal disconnects in `deactivate_relic` and guards against double connection.

### D6. Catalog (authoritative table)
Stats are `+BLOCK/+ATK/+SPD`. Hook tags: A status hooks, B attack event, C player hooks, `-` none.

| # | Item | Slot | Rarity | Stats / dice | Effect | Hooks |
|---|---|---|---|---|---|---|
| 1 | Kindling Bundle | Trinket | Common | none | Block: 1 Scorch to random enemy | - |
| 2 | Pine-Tar Gloves | Trinket | Uncommon | +1 ATK | +1d4 vs targets already carrying a debuff | B |
| 3 | Fur-Lined Cap | Helmet | Common | +1 BLK | Immune to Speed Down | C |
| 4 | Breaker Pick | Weapon | Uncommon | 1d6 | Sunder if target keeps block | - |
| 5 | Riposte Foil | Weapon | Uncommon | 1d4, +1 SPD | After Block, next attack +1d6 | - |
| 6 | Frostborn Circlet | Helmet | Uncommon | +1 BLK | Thaw: +1 Attack Up | - |
| 7 | Warding Talisman | Trinket | Uncommon | none | Ward at combat start | A |
| 8 | Emberweave Tunic | Armor | Uncommon | +1 BLK | Gain Scorch: 1d4 block per stack | A |
| 9 | Rime Bead | Trinket | Uncommon | +1 SPD | Hit on Slowed enemy: Brittle | B |
| 10 | Hunter's Snare | Trinket | Rare | none | Enemies start with 1 Speed Down | - |
| 11 | Shatterglass Hammer | Weapon | Mythic | 1d8, -1 SPD | 4th hit Freeze; hit Frozen: +1d8, Brittle, ends the Freeze | - |
| 12 | Cinderbrand | Weapon | Rare | 1d6, +1 ATK | Scorch per hit; detonate at 3 for 1d4 per stack | A |
| 13 | Bulwark Maul | Weapon | Rare | 1d6 | +1d4 per 5 block (max 3d4) | - |
| 14 | Cracked Visor | Helmet | Rare | +1 ATK | While Brittle: attacks +1d8 | A, B |
| 15 | Sentinel's Aegis | Armor | Rare | +2 BLK | Ward at start, regain every 3rd Block | A |
| 16 | Carrion Thurible | Trinket | Rare | none | Pass DoTs to 1 random enemy on death | - |
| 17 | Quicksilver Spurs | Trinket | Rare | +1 SPD | Hit Slowed/Frozen: next bar 25% | B, C |
| 18 | Reactive Plate | Armor | Rare | +3 BLK, -1 SPD | Block break: 2d4 + Brittle to attacker | - |
| 19 | Mirrorscale Mail | Armor | Mythic | +2 BLK | Ward; absorbed debuff hits all enemies | A |
| 20 | Phoenix Feather | Trinket | Mythic | none | Single use: survive, 30% HP, 1 Scorch all, then removed | C |
| 21 | Hunter's Mercy | Weapon | Mythic | 1d8 | Execute <30% HP (bosses: extra 1d8); kill: bar to 50% | C |
| 22 | Frostfire Pike | Weapon | Mythic | 1d8 | Alternate 1 Scorch/1 Speed Down; both: Brittle+Sunder once until one wears off | A |
| 23 | Glass Heart | Trinket | Mythic | +4 ATK, +2 SPD | Brittle returns 3 actions after consumed | A |
| 24 | Warden's Visage | Helmet | Mythic | +1 SPD | +1 stack on stacking statuses you inflict | A |

Block-break detection (Reactive Plate) uses `player_damaged` (fired before block is applied) and compares the modified damage with `stats.block` at that moment. Thaw detection (Frostborn Circlet) connects to the player's `atb_mods.freeze_ended` at combat start.

### D10. Damage modifiers are dice, not percentages
Brittle used to add 50% to the next hit. It now makes the next hit that was rolled with dice roll one extra die of the same size (a 1d6 hit becomes 2d6), so it scales with whoever is hitting instead of with a percentage of a number.
- `DamageEffect` carries `die_sides` and passes it to `take_damage(amount, modifier, source, die_sides)`. The player attack reports the weapon die (1d4 with no weapon); every enemy attack action reports its `dice_value`.
- The actor owns a `brittle_next_hit` flag (like Sunder's `ignore_block_next_hit`) and rolls the extra die inside `take_damage`; the status only sets the flag and ends once it is spent.
- Flat hits (`die_sides` 0: Thorns, Poison/Burn/Scorch ticks, `NO_MODIFIER` hits) neither use nor spend Brittle.
- The extra die is a single die of the hit's size, not another full roll, and never multiplies the flat attack bonus.
Alternative: keep the percentage and lower it. Rejected: a percentage still grows with every damage source, while a die grows with the die size only.
Item effect amounts (damage, block, healing) are dice too; gear stat bonuses and status stack counts stay numbers.
Other percentage values (execute and revive thresholds, turn-bar shares, enemy `bonus_multiplier`) are not damage multipliers or are existing enemy tuning and are unchanged.

### D7. Art production: pixel maps as source, generated PNGs as output
Icons are authored as text pixel maps (one character per pixel, a per-file legend into the shared palette) under `art/src/items/` and `art/src/statuses/`, and a headless Godot tool (`tools/build_icons.gd`) renders them to PNG. A maintainer can instead hand-draw in Aseprite and drop the PNG in, as long as it passes the same review; the source map is then optional.
Why: pixel maps are diffable, reviewable in a PR, reproducible, and let palette changes be applied to all icons at once. The repo already carries an `.aseprite` file, so hand-drawn replacements stay supported.
Alternative: only hand-drawn PNGs. Rejected as the sole path because there is no way to review or regenerate them, and no artist is guaranteed.

### D8. Art direction (applies to all 30 icons)
- **Size and format:** items 16x16, statuses 10x10, RGBA PNG, transparent background, no anti-aliasing, no semi-transparent pixels except intended glow.
- **Palette:** one shared palette of about 24 colours extracted from the existing icons in the first art task (so the new work matches what ships) plus 4 accent hues reserved for statuses: ice cyan (Freeze), amber-orange (Scorch), ash grey-violet (Ashen), pale gold (Ward). Brittle uses cracked white-blue; Sunder uses iron grey with a red split.
- **Light:** single source from the top left. Highlight on the top-left edge, core shadow bottom-right, one-pixel darker outline on the shadow side only (selective outlining), full dark outline only where the silhouette would otherwise merge into the dark inventory background.
- **Shading:** three tones per material plus one highlight pixel. No dithering at 16x16.
- **Silhouette first:** every icon is drawn as a one-colour silhouette and checked before shading; weapons run diagonally (hilt bottom-left), helmets and armor face front, trinkets are centred.
- **Rarity language (detail, not frame):** common = 2 materials, clean shape; uncommon = adds a secondary material or accent pixel; rare = adds a glow, gem or contrasting rim light; mythic = a unique motif only mythics use (a one-pixel halo/spark pattern) and the highest-contrast highlight.
- **Status icons (10x10):** shape-coded as well as colour-coded, one dominant shape each: Freeze = snowflake/ice block, Brittle = cracked shard, Sunder = split shield, Scorch = tall flame with ember pixels (distinct from Burn's round flame), Ashen = drifting flakes over a dull block icon, Ward = ringed bubble/rune. Each is checked in greyscale.
- **Context test:** every icon is previewed in the inventory slot, the relic bar, the shop and the tooltip on the three act backgrounds.

### D9. Item art briefs
Silhouette notes per item, to be refined in the art direction task:
1. Kindling Bundle: tied twigs with a single orange ember pixel.
2. Pine-Tar Gloves: dark glove, tar sheen highlight.
3. Fur-Lined Cap: cone cap with white fur rim.
4. Breaker Pick: short pickaxe, chipped grey head.
5. Riposte Foil: thin diagonal blade with a bell guard.
6. Frostborn Circlet: thin silver band with an ice-blue gem.
7. Warding Talisman: round charm with a pale gold rune.
8. Emberweave Tunic: dark tunic with orange stitched hem.
9. Rime Bead: frosted bead on a cord, white speckles.
10. Hunter's Snare: coil of rope loop with a small trigger.
11. Shatterglass Hammer: hammer head of cyan glass with a crack line.
12. Cinderbrand: blade with glowing orange runes and soot edge.
13. Bulwark Maul: blunt maul with a shield-shaped head.
14. Cracked Visor: helm with a fractured red visor slit.
15. Sentinel's Aegis: broad chestplate with a gold ringed sigil.
16. Carrion Thurible: hanging censer with green-violet smoke.
17. Quicksilver Spurs: winged spur, silver with blue motion pixels.
18. Reactive Plate: spiked plate with a red fracture at the centre.
19. Mirrorscale Mail: scale armor with mirror highlight pixels, mythic spark.
20. Phoenix Feather: long ember-gradient feather, mythic halo.
21. Hunter's Mercy: curved cleaver with a notch tally, mythic spark.
22. Frostfire Pike: spear with a half-ice, half-flame head, mythic halo.
23. Glass Heart: heart of cracked glass with a pulsing inner red pixel.
24. Warden's Visage: antlered mask crown with three glow dots.

## Risks / Trade-offs

- **[Ward interception misses a debuff path]** Some enemies add statuses by calling `add_status` directly, others through `StatusEffect`. → Both end in `add_status`; a headless test applies every debuff through both routes.
- **[Item extra damage consumes Brittle/Sunder]** Items that deal a second hit can spend a status they just applied. → Order is fixed in the design (apply status after the bonus hit) and the verify tool asserts it for Shatterglass and Rime Bead.
- **[Signal leaks across combats]** Shared resources plus `Events` subscriptions can double-fire in later combats. → D5 rule, enforced by a verify check that runs two combats back to back.
- **[Mythic count shifts balance]** 8 mythics instead of 2 changes how often a mythic is a repeat. → Intentional; weights unchanged. Difficulty-score impact is tracked in the verify report.
- **[Conditional items drop in the wrong act]** Fur-Lined Cap, Frostborn Circlet and Emberweave Tunic have value in one act. → Each keeps a flat baseline stat; act-weighted pools stay a documented non-goal.
- **[Art volume and consistency]** 30 icons by hand is the largest cost. → Palette extraction first, pixel-map pipeline, contact-sheet review, and art tasks sequenced before wiring so nothing ships with a stand-in.
- **[Pixel maps are not hand-drawn feel]** Generated art can look stiff. → The review checklist includes a "hand-made" pass (no symmetric stiffness, deliberate off-pixels), and any icon can be replaced by an Aseprite PNG.
