# Proposal

## Why

After a full playthrough of the rebalanced game, the difficulty adjustment (DDA) only punishes: when the player is strong it turns campfires and events into battles after every fight until the map is nothing but battles, and when the player is weak it only swaps one room type, which never makes a fight easier. The DDA should help a struggling player in ways that change the run, and its conversions into battles need a limit.

## What Changes

- A weak run (score at or below 35) gets tier-0 battles instead of tier-1 ones, the mirror of the existing tier-2 upgrade for strong runs.
- A weak run always gets a relic from a regular battle.
- A weak run (score at or below 30) heals an extra share of max health when resting at a campfire.
- At most 2 rooms per act can be converted into battles by the DDA (counting every kind of conversion to a battle), so the map cannot turn into only fights.
- After a battle, a player holding a lot of unspent gold (200 or more) gets one upcoming battle swapped for a shop, once per act, if no shop is already ahead.
- Once per run, a player at 20% health or less after a battle gets one upcoming battle swapped for a campfire.

## Capabilities

### New Capabilities

None.

### Modified Capabilities
- `dda-room-adjustment`: weak-run assistance (tier-0 battles, campfire bonus heal), a per-act limit on conversions into battles, the hoarded-gold shop swap and the once-per-run emergency campfire.
- `reward-drop-rates`: a weak run always gets a relic from a regular battle.

## Impact

- Code: `custom_resources/dda.gd`, `dda_config.gd` and `.tres`, `dda_state.gd`, `dda_conversion.gd`, `reward_config.gd`, `reward_rules.gd`, `scenes/run/run.gd` (battle choice, campfire, DDA calls), `scenes/campfire/campfire.gd`.
- Tests: `tools/verify_dda.gd`, `tools/verify_reward_drops.gd`; the simulation `tools/simulate_rewards.gd` reports how many battles the DDA adds.
- Saves: new DDA state fields default to unused, so older saves load.
- Unchanged: the score arithmetic, the tier-2 upgrade, the existing shop and treasure swaps, enemy scaling.
