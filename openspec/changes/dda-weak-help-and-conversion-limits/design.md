# Design

## Context

- DDA decisions live in `DDA.decide_after_*` (pure) and `DDA.execute` runs them through `Map.convert_rooms`. Today a strong score (65 and up) adds CAMPFIRE or EVENT to MONSTER after every battle, and at 70 and up after every campfire and treasure room. Nothing limits how often, so a long strong streak turns the map into battles only (playtest).
- A weak score (35 and below) only adds MONSTER to SHOP or CAMPFIRE, one room per battle. The tier-2 upgrade (score 75 and up) has no easier counterpart.
- Tier-0 battles exist in every act (`battles/mapN/tier0`).

## Goals / Non-Goals

**Goals:** weak runs get help that changes fights, drops and healing; conversions into battles are bounded; hoarded gold and near-death states get a response.
**Non-Goals:** changing the score arithmetic, the tier-2 upgrade, enemy scaling, or the existing shop and treasure swaps.

## Decisions

1. **Tier-0 downgrade mirrors the tier-2 upgrade.** `_prepare_battle` in `run.gd` swaps a tier-1 battle for a random tier-0 battle of the act when the score is at or below `tier0_downgrade_score` (35, same as the weak battle score). Alternative: scale enemy health. Rejected: tier-0 fights are authored easy fights, and nothing new to tune.
2. **Guaranteed drop in `RewardRules.battle_drops_relic`**, driven by `weak_drop_score` (35) in `RewardConfig`, so the existing pity and gold logic stays in one place. It applies while the score stays low; every relic raises the score, so a weak run leaves that state after a few drops.
3. **Campfire bonus.** `DDA.campfire_bonus_heal(score)` returns `campfire_weak_heal_share` (0.15) when the score is at or below `campfire_low_score` (30). The run passes it to the campfire scene, which heals 30% plus the bonus.
4. **Per-act budget for conversions into battles.** `DDAState.battle_conversions` counts rooms the DDA turned into battles this act; `max_battle_conversions_per_act` (2) caps it. Decision functions only add a conversion to a battle while budget remains, and `execute` counts the rooms that really changed. Alternative: a cooldown of N rooms between conversions. Rejected: a count is simpler to explain, test and tune, and matches the existing once-per-act flags.
5. **Hoarded gold.** `decide_after_battle` adds MONSTER to SHOP when gold is at least `hoard_gold` (200), the per-act `hoard_shop_used` flag is free, and no shop is reachable ahead (the run passes `shop_ahead`). 200 is about one mythic and about 85% of the median shop wallet in the simulation.
6. **Emergency campfire.** `decide_after_battle` adds MONSTER to CAMPFIRE when the health share is at or below `emergency_hp` (0.2) and `emergency_campfire_used` is false. The flag is not reset between acts. It is skipped when a weak-run MONSTER to CAMPFIRE is already queued, so one battle never loses two rooms to campfires.
   A player holding that much gold is also exempt from the high-score "shop becomes a battle" swap, so the shop the DDA just added is not taken away on the next fight. A weak, hurt and rich player can get a campfire and a shop in the same decision; both help, so that is allowed.
7. **Flags are set only when a room changed**, as for the shop flag, by marking the conversion (`uses_hoard_flag`, `uses_emergency_flag`) and handling it in `execute`.

## Simulation results (apply)

`tools/simulate_rewards.tscn` plays the real DDA decisions for a strong player (score 80, wins healthy) on a 3-wide, 11-floor act (floor 5 all treasure, floor 10 the pre-boss campfires), over 2000 acts:

| Setup | Battles on the player's path | Pre-boss campfire survives |
|---|---|---|
| Old: no limit, pre-boss campfire convertible | 3.9 | 24% |
| Pre-boss campfire fixed, no limit | 3.1 | 100% |
| Pre-boss fixed, limit 2 per act (current) | 3.0 | 100% |

- The main cause of the "map full of fights" was the pre-boss campfire floor, where every room is a campfire and so the first conversion always had a target; fixing that floor (see `rebalance-v3-economy-and-shops`) does most of the work. The per-act limit is a safety net: it trims a further 0.1 battle on this model, where the player avoids battles, and more for a player who cannot.
- The model assumes a player who avoids battles; a player who must fight sees more.

## Risks / Trade-offs

- [A weak run can stay weak: always-dropping relics lift the score so help ends quickly] → intended; the thresholds are data.
- [The cap of 2 may be too low or too high] → it is one value in `dda_config.tres`; the simulation reports battles added per act.
- [Tier-0 fights pay slightly less gold (50-60 against 60-70)] → accepted; it is a small cost on top of the extra relic.
- [Older saves have no new fields] → defaults mean "nothing used", which is correct for runs saved before the change.

## Migration Plan

Config and code only. Roll back by reverting the commit; saved runs keep working because the extra fields are optional.
