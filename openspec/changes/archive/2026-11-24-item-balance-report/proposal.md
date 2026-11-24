## Why

Playtesters say the numbers feel too high, and the `ROADMAP.md` budgets (about 1 point common, 2 uncommon, 3 rare) do not match the data: Heavier Armor is uncommon with +8 BLOCK / -2 SPEED, Glass Heart is rare with +4 ATTACK / +2 SPEED, Great Axe is an uncommon 1d12, and several starter items have no rarity line. There is no single place to see every relic, so tuning is guesswork. The report is the data source for `reward-drop-rates` and `item-balance-pass`.

## What Changes

- Add a headless Godot script that scans `relics/` (excluding `relics/1old`) and prints one table of every relic, grouped by rarity.
- Columns: name, slot, rarity, stat total, weapon dice and average damage, effect text, statuses mentioned, consumable marker.
- Flag every relic whose stat total or weapon average is above its rarity budget, and relics with missing or suspicious data (for example `weapon_dice_attack` set with no `weapon_dice_amount`).
- Print a summary per rarity (count, average stat total, budget).
- No gameplay change and no resource edits.

## Capabilities

### New Capabilities
- `item-balance-report`: headless report of every relic with budget flags.

### Modified Capabilities

## Impact

- New `tools/report_item_balance.gd` and `.tscn`, run like the `tools/verify_*.tscn` suites.
- Reads `relics/**/*.tres` and `relics/**/*.gd` only; changes nothing at runtime.
