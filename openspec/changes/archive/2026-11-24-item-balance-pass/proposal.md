## Why

After `item-balance-report`, `reward-drop-rates` and `enemy-scaling`, the number of relics a player holds and the enemy strength are known, so relic numbers can finally be tuned against them. Some outliers are already visible: Cracked Visor and Glass Heart (+4 ATTACK / +2 SPEED at rare) are untouched, Heavier Armor (+8 BLOCK / -2 SPEED), Great Axe (1d12) and Barbarian Armor (dice sides without an amount) look off. Frostfire Pike and Phoenix Feather were already nerfed in the item-slop merge and only need a recheck.

## What Changes

- Tune relic numbers so every relic is within its rarity budget in the report, or is listed as a deliberate exception with a reason.
- Fix data errors the report flags (for example Barbarian Armor's weapon dice fields).
- Retune the known candidates: Cracked Visor, Glass Heart, Heavier Armor, Great Axe, and recheck Frostfire Pike and Phoenix Feather against the new drop rates and enemy scaling.
- Add a small headless combat simulator that plays a relic loadout against act enemies so changes are judged by numbers (turns to kill, HP lost per fight) instead of feel.
- Keep the dice rule: item effects use dice; gear stats and stack counts stay numbers.

## Capabilities

### New Capabilities
- `item-rarity-budget`: the budget every relic must respect, and how exceptions are recorded.
- `balance-simulator`: a headless simulation of relic loadouts against enemies.

### Modified Capabilities

## Impact

- `relics/**/*.tres` and `.gd` for the tuned relics, their tooltips, and `tools/verify_item_pool_expansion.gd` and `verify_item_pools.gd` where they assert numbers.
- New `tools/simulate_balance.gd` and `.tscn`.
- Depends on `item-balance-report`, `reward-drop-rates` and `enemy-scaling` landing first.
