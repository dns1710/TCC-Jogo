# Tasks

## 1. Config and state

- [x] 1.1 Add `tier0_downgrade_score`, `campfire_weak_heal_share`, `max_battle_conversions_per_act`, `hoard_gold`, `emergency_hp` to `dda_config.gd`, `weak_drop_score` to `reward_config.gd`, and `battle_conversions`, `hoard_shop_used`, `emergency_campfire_used` to `dda_state.gd` (the first two reset each act, the emergency flag does not); verify the resources load and `reset_for_act` clears exactly the per-act fields in `tools/verify_dda.gd`.
- [x] 1.2 Add `uses_hoard_flag` and `uses_emergency_flag` to `DDAConversion`; verify the string form distinguishes them.

## 2. Weak-run help

- [x] 2.1 Tier-0 downgrade in `run.gd::_prepare_battle` through `DDA.should_downgrade_to_tier0`; verify score 30 gives a tier-0 battle, 50 keeps tier 1 and 80 still upgrades to tier 2.
- [x] 2.2 Guaranteed relic drop for weak runs in `RewardRules.battle_drops_relic`; verify a failed roll at score 30 still drops and resets the pity counter, and at score 50 behaves as before.
- [x] 2.3 Campfire bonus heal through `DDA.campfire_bonus_heal` and `Campfire.bonus_heal_share`; verify a weak rest at 40 max health heals 18 and an average rest heals 12.

## 3. Conversion limits and new swaps

- [x] 3.1 Per-act budget for conversions into battles in `decide_after_battle`, `decide_after_campfire` and `decide_after_treasure`, counted in `DDA.execute`; verify that after 2 conversions a strong score adds none and that a new act resets the count.
- [x] 3.2 Hoarded-gold shop swap in `decide_after_battle` with `shop_ahead` from the run; verify 250 gold with no shop ahead converts a battle to a shop once per act, a shop ahead blocks it, and the flag stays free when nothing converted.
- [x] 3.3 Emergency campfire in `decide_after_battle`; verify 15% health converts once per run, 30% health does not, and it does not double up with the weak-run campfire swap.
- [x] 3.4 Pass the state and `shop_ahead` from `run.gd` to the decision functions; verify the DDA run flow in `tools/verify_dda.gd` still passes.

## 4. Simulation and integration

- [x] 4.1 Add to `tools/simulate_rewards.gd` a DDA conversion model that reports battles added per act with and without the cap; verify it prints the numbers.
- [x] 4.2 Run the full verify suite headless; verify every suite exits 0.
