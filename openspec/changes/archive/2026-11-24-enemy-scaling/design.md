# Design

## Context

- `Enemy.set_enemy_stats` stores `value.create_instance()`, so every spawned enemy already owns a private copy of its stats; scaling can be applied to that copy.
- Enemy hits are `Dice.roll(dice_amount, dice_value, enemy.stats.attack)` per attack action, with `damage_effect.die_sides = dice_value` so Brittle works.
- Bosses: Big Chicken (40 HP, act 1), Bear Boss (60), Krampus (90, act 2), Fire Dragon (90, act 3); regular health ranges 5 to 40.
- The run knows the current act (`ACTS[act_index]`) and passes it to the map; battles receive `battle_background` from it, so passing scaling the same way fits the existing flow.

## Goals / Non-Goals

**Goals:** per-act numbers in one resource; no edits to enemy `.tres` files; act 1 unchanged by default.
**Non-Goals:** new enemies, new boss mechanics, per-battle DDA scaling (DDA already picks tiers).

## Decisions

- **Scale at stats creation.** After `create_instance()`, set `max_health = ceil(base * enemy_health_scale)`, `health = max_health`, `attack += enemy_attack_bonus`. Alternative (duplicating enemy `.tres` per act) multiplies files and drifts.
- **Boss extra dice** add `boss_extra_dice` to `dice_amount` for attacks of enemies flagged as boss, using the attack's own die size, so Brittle's extra die stays consistent. Alternative (flat bonus) contradicts the "dice, not flat numbers" rule.
- **Attack bonus is flat on purpose.** It is the flat part of the roll like gear stats, which the rule allows to stay a number.
- **Starting values** (to be tuned): act 1 = 1.0 / 0 / 0, act 2 = 1.25 / +1 / 1, act 3 = 1.5 / +2 / 1. Chosen so act 1 plays as today and bosses grow faster than regulars.
- **Which actions scale dice** is declared per action script by reading a shared `Enemy.extra_attack_dice` value instead of each script knowing the act.

## Results (apply)

Final act values: act 1 = x1.00 / +0 / 0 dice, act 2 = x1.25 / +1 / 0 dice, act 3 = x1.50 / +2 / 1 die.

- Boss dice are 0 in act 2 on purpose. With 1 extra die Krampus (3d8 strike, attack 4) has a worst hit of 45 including Brittle, above the player's 40 starting health. At 0 it is 37. Act 3's Fire Dragon with 1 extra die has a worst hit of 37.
- "Bosses outpace regular enemies by ratio" was dropped as a rule: a flat attack bonus helps small hits proportionally more, so the ratio compares unfairly. The check prints the growth instead (act 2: bosses x1.10, regular x1.19; act 3: bosses x1.58, regular x1.37).
- Krampus is already the hardest hit in the game at act 1 values (avg 17.5, worst 36 with Brittle against 40 health); worth a look in `item-balance-pass` or a playtest.
- Boss status is the new `EnemyStats.is_boss` flag, set on Bear, Big Chicken, Krampus and Fire Dragon. All attack actions roll through `EnemyAction.roll_attack`.

## Risks / Trade-offs

- [Boss extra dice and Brittle stack into very high burst] → the check prints worst-case boss hit (all dice max plus Brittle) per act; tune until it stays under the player's expected health.
- [Rounding makes 5 HP enemies jump] → use ceil with a minimum gain of 0 and review chicken and fire imp in the check output.
- [Scaling and fewer relics both toughen runs] → apply after `reward-drop-rates` and tune together in `item-balance-pass`.

## Open Questions

- Final scale numbers are chosen in apply from the check output; the structure does not depend on them.
