## Why

Enemies have fixed stats per type (chicken 5 HP up to fire dragon 90 HP), so a later act is only harder through which enemies appear, and relic-rich players outgrow every fight. Brittle now adds one extra die of the hit's size, so enemy dice already matter; the missing piece is a way to raise enemy health and attack per act and give bosses extra dice without editing every enemy resource.

## What Changes

- `Act` resources gain `enemy_health_scale` (multiplier on max health), `enemy_attack_bonus` (flat addition to the enemy attack stat used as the flat part of `Dice.roll`) and `boss_extra_dice` (extra dice for boss attacks).
- Enemies and bosses spawned in an act are scaled when their runtime stats are created, never by editing the shared enemy `.tres` files.
- Initial values: act 1 = 1.0 / +0 / 0 (behaves as today), acts 2 and 3 higher; exact numbers are tuned in apply from `item-balance-report` data.
- A headless check prints each enemy's effective health and average hit per act.

## Capabilities

### New Capabilities
- `enemy-scaling`: how act scaling values change enemy health, attack and boss dice.
- `act-difficulty-curve`: how the three acts relate in enemy strength.

### Modified Capabilities

## Impact

- `custom_resources/act.gd` and `acts/*.tres`, `scenes/enemy/enemy.gd` (stats creation), enemy attack actions that read `dice_amount` (`enemies/*/*_attack_action.gd`, `scenes/enemy/melee_attack_action.gd`, `telegraphed_strike_action.gd`), the battle setup that knows the current act.
- New `tools/verify_enemy_scaling.tscn`; `verify_act_enemies` re-run.
- Should land after `reward-drop-rates` (fewer relics changes how strong the player is).
