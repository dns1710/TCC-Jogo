# Design

## Context

- The report from `item-balance-report` gives per-relic stat totals, weapon averages, flags and statuses. Budgets start at 1 / 2 / 3 stat points for common / uncommon / rare and are confirmed in that change.
- Player combat: ATB with Attack (weapon dice + ATTACK) and Block (+5). Brittle, Sunder, Scorch, Burn, Poison and Freeze are applied through `ItemFx`.
- After the earlier changes a player holds fewer relics and meets scaled enemies, so old tuning assumed the wrong baseline.
- Nothing in the repo simulates combat; existing `verify_*` scripts assert behavior, not balance.

## Goals / Non-Goals

**Goals:** relics within budget or documented exceptions; a repeatable way to compare before and after.
**Non-Goals:** new relics, new statuses, changing enemy data (done in `enemy-scaling`), art.

## Decisions

- **Budget compliance is the contract**, not the simulator. The simulator informs numbers but the check that blocks the change is the report: no unflagged-over-budget relics left without an exception entry.
- **Exceptions file**: a short list inside this change's design (relic, measure, reason) and mirrored as a constant in the report script, so intentional outliers (for example a tradeoff item like Heavier Armor with a speed penalty) stop being flagged.
- **Simulator is deliberately small**: abstract turn-based loop using the same dice helpers, player ATB speed, block action and enemy attack tables; supports weapon dice, stat bonuses and a few effect hooks. It does not run the Godot scene. Alternative (driving the real battle scene headless) is more faithful but slow and fragile.
- **Targets** are proposed defaults, confirmed with the owner before tuning: median fight costs a baseline loadout 20 to 35% of max health in act 1, and a fully built loadout clears act-3 regular fights in roughly 2 to 4 attacks.
- **Tuning order**: data errors first, then outliers by the report, then simulator comparison, then tooltips and verify scripts.

## Results (apply)

**Targets confirmed with the owner (progression targets):** a typical build loses 20-35% of its HP per regular fight in act 1, 25-40% in act 2 and 30-45% in act 3.

**Simulator.** `tools/simulate_balance.tscn` (see its header for options): presets, `--loadout`/`--vs` comparison, `--rank=1` relic ranking, `--builds=N` random builds, `--no-scaling=1`, `--breakdown=1`. Seeded and repeatable. It simulates weapon dice, stat bonuses, turn-bar pacing, enemy dice and act scaling, Glass Heart's Brittle, Cracked Visor and a few dice effects. It does NOT simulate burn, poison, freeze, ward, thorns, enemy block or smart targeting, so relics built on those look weaker than they are (marked `~`).

**What a point is worth** (HP saved per fight, from the ranking): SPEED about 2.2, ATTACK about 1.55, starting BLOCK about 0.6. The report therefore weights them 1.0 / 0.7 / 0.3 (it first used BLOCK at 0.5 from an early estimate, then re-weighted from the ranking). With those weights no relic is over its stat budget and the exception list is empty.

**Relic changes**

| Relic | Before | After | Why (act 2, kit + relic, HP saved) |
|---|---|---|---|
| Glass Heart (mythic) | +4 ATK, +2 SPD | +3 ATK, +2 SPD | saved 10.1 HP, far above every rare; now 7.5 |
| Heavier Armor (rare) | +8 BLOCK, -2 SPD | +10 BLOCK, -1 SPD | worst relic in the game (-1.9, 1% win); now about 0 |
| Heavy Plate, Heavy Helmet (uncommon) | +3 BLOCK, -1 SPD | +4 BLOCK | both lost HP against the kit item (-1.3 / -1.1); now +0.7 / +1.5 |

Reviewed and left alone: Great Axe (1d12 is exactly the rare cap, saves 4.5 against Scout Scarf 5.4 and Shadow Sneakers 8.3), Cracked Visor (inside budget; +0.7 alone, it is a Glass Heart combination piece: with Glass Heart the pair adds 22 win-rate points), Shadow Sneakers (+3 SPEED sits on the 1 / 2 / 3 SPEED ladder of Boot, Speed Badge and itself, so it ranks first among rares; SPEED is the strongest stat), Frostfire Pike, Hunter's Mercy and Phoenix Feather (their effects are statuses or one-shots the simulator cannot measure; recheck by playtest).

**Data fixed earlier in this change:** Needle had no die sides and Barbarian Armor had a stray die field (see `verify_weapon_dice`).

**Open finding for the owner.** With the progression targets the simulator says act 1 is right (a typical build loses a median 28%, target 20-35%), but acts 2 and 3 are far above target (median 84% in act 2 against 25-40%, 100% in act 3 against 30-45%). Without any act scaling the median is 51% and 77%, so most of the gap is the base act 2 and 3 enemies (for example Snow Golem hits 1d12-ish and the alpha pack and banshee-and-wolves fights are never won by typical builds), and the scaling from `enemy-scaling` adds the rest. Relic tuning alone cannot close it. The simulator does not model several relic effects or smart play, so the absolute act 2 and 3 numbers are probably harsher than real play; this needs a playtest or an owner decision before enemy numbers move.

## Risks / Trade-offs

- [Simulator disagrees with real play] → keep it as a ranking tool, back it with playtest notes, and never use it to override the budget check.
- [Nerfs make relics dull] → prefer changing the cost side (drawback, trigger condition) over lowering a single number, as in the item-slop merge.
- [Tooltips drift from code] → every tuned relic updates its tooltip and the assertions in the verify scripts in the same task.

## Open Questions

- Exact simulator targets (the 20 to 35% and 2 to 4 attack ranges) are confirmed with the owner at the start of apply; changing them only changes tuned numbers, not the structure.
