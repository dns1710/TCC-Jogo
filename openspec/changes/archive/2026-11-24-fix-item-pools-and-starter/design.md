# Design

## Context

Items are `Relic` resources in `relics/`. Three pools decide where they drop, each an array wired in a scene: the reward pool (`battle_relic_pool` in `run.tscn`), the treasure pool (`treasure_relic_pool` in `treasure.tscn`, which also skips commons in `treasure.gd`) and the shop pool (`shop_relics` in `shop.tscn`). `Relic.can_appear_as_reward()` returns false for items flagged `starter_relic`.

State found by reading the repository, after the `items` branch merge (PR #38):
- `run.gd` `_start_new_run` preloads `relics/helmet/scout_scarf.tres`, adds it without score effects and equips it. The merged branch changed this from `relics/armor/slow.tres` (now named Heavier Armor).
- Not in any pool: `barbarian` (Barbaridade), `slow` (Heavier Armor), `icy` (Snow Balls), `shadow` (Shadow Sneakers), `receba` (Gloves).
- `hunters_axe` (ex-Sadistic) is in all three pools but flagged `starter_relic = true`, so it never drops.
- Coat no longer exists. Scout Scarf and Scout Sash are rare and in all three pools, so after the change the Scarf can drop like any rare.
- Other gaps between pools (for example five reward-only items) are deliberate and stay.

See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Itemless new runs; every droppable item reachable; a test that stops this drifting again.

**Non-Goals:**
- Merging the three pools, changing which pool an existing item is in, stats, balance, DDA thresholds.

## Decisions

**1. Delete the three starter lines; keep the item.** The Scout Scarf stays a normal rare drop. Alternative: keep a starter but a different one; rejected, the intent is an empty start.

**2. Add each orphan to the pools that fit its rarity.** Heavier Armor, Barbarian Armor, Snowballs and Shadow Sneakers go to reward, treasure and shop; Gloves (common) goes to reward and shop since `treasure.gd` ignores commons. Pool arrays are edited in the `.tscn` files. Alternative: one shared pool resource for all three scenes; rejected for now, pool differences are deliberate and a restructure is a larger change.

**3. Clear `starter_relic` on Hunter's Axe.** It is already pooled; the flag was the only thing blocking it. Its tooltip (1d10) and dice already match.

**4. Gloves tooltip uses BBCode.** Every relic tooltip surface (hover tooltip, relic tooltip, tooltip) is a `RichTextLabel` with BBCode on, so styling `receive` (gold with a small wave) works everywhere. Alternative: plain text with caps; rejected, the request is for differently styled text.

**5. Guard test as a scene.** `tools/verify_item_pools.tscn` reads the three pools from the scenes, scans `relics/` (skipping `1old/`), and fails on an item that is not a starter and is in no pool. It also checks that no item is still flagged as a starter, that ids are present and unique, that the five added items sit in the expected pools, and that a new run starts with an empty relic handler. Like the other `tools/` suites it backs up and restores `user://savegame.tres`.

## Risks / Trade-offs

- [DDA relic-count thresholds assumed one starting relic] → Out of scope; they are tunable in `dda_config.tres` and can be lowered by one after a playtest.
- [Itemless start changes the first fight's feel] → That is the intended difficulty; the first-battle reward still gives a weapon and a piece of gear.
- [Heavier Armor (+8 block, -2 speed) and Shadow Sneakers (+3 speed) are strong in the pools] → Stats are out of scope; flag after playtesting.
- [Scene edits to three `.tscn` files conflict with parallel work] → Work is on `main`, the `items` branch is already merged; keep the edits to the array lines and their `ext_resource` entries.
- [Existing saves] → A save made before the change keeps its starting relic; only new runs are itemless.
