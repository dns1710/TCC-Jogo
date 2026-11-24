# Proposal

## Why

Players are meant to start a run itemless, which is why the first fight is easy, but `run.gd` still gives and equips a fixed starting relic (it was Heavier Armor, and after the `items` branch merge it is the Scout Scarf). Separately, several coded items can never drop because they were never added to a pool, and Hunter's Axe is in every pool but flagged as a starter item, so the drop rules skip it. These items are invisible to players and to testing, and nothing warns when an item is added without a pool.

## What Changes

- Remove the fixed starting relic from `_start_new_run`: a new run starts with no relics. The Scout Scarf and Heavier Armor stay as normal drops.
- Add the unpooled items to all three pools (reward, treasure, shop): Heavier Armor, Barbarian Armor, Snowballs, Shadow Sneakers. Gloves is common, which the treasure pool never offers, so it goes to the reward and shop pools only.
- Clear the starter flag on Hunter's Axe so it can drop (including as a first-battle weapon reward).
- Rename Barbaridade to "Barbarian Armor" and Snow Balls to "Snowballs".
- Change the Gloves tooltip to "You _receive_ unexplainable confidence, +1 attack", with "receive" styled differently (gold, with a small wave) to keep the joke.
- Add a headless test that fails when a non-starter item belongs to no pool, and that a new run starts with no relics.

Already done by the merged `items` branch, so not part of this change: Coat was deleted, and Sadistic became Hunter's Axe.

Out of scope: changing existing pool membership (it is deliberate), item stats and balance, the DDA relic-count thresholds, existing saves.

## Capabilities

### New Capabilities
- `item-availability`: what a run starts with and which items can drop.

### Modified Capabilities

None. `openspec/specs/` has no existing specs.

## Impact

- Code: `scenes/run/run.gd` (starter lines), `scenes/run/run.tscn`, `scenes/treasure/treasure.tscn`, `scenes/shop/shop.tscn` (pool arrays).
- Data: `relics/armor/barbarian.tres`, `relics/armor/slow.tres` (no edit, only pooled), `relics/weapon/icy.tres`, `relics/trinket/receba.tres`, `relics/weapon/hunters_axe.tres`.
- New: `tools/verify_item_pools.tscn` and script.
- Existing runs: a save made before the change keeps its starting relic; only new runs start itemless.
- Work is done directly on `main`.
