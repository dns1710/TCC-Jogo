# Design

## Context

Relics are `Relic` resources (`relics/<slot>/*.tres`) with `bonus_atk`, `bonus_blk`, `bonus_spd`, `weapon_dice_attack` (die sides), `weapon_dice_amount`, `rarity` (0 common to 3 mythic), `equip`, and a `tooltip` that carries the effect text. Effect logic lives in the matching `.gd`. The last merge made item effects dice-based (`Dice.roll`, `ItemFx.hit(..., die_sides)`), and Phoenix Feather now calls `consume_relic`. Headless checks already exist as `tools/verify_*.tscn`, run with the Godot console binary.

## Goals / Non-Goals

**Goals:** one readable table; budgets in one constant block; reproducible output a later change can diff.
**Non-Goals:** editing relics, simulating combat (that is `item-balance-pass`), a UI.

## Decisions

- **Load by scanning, not a list.** Walk `res://relics/` recursively and load every `.tres` whose script extends `Relic`; skip `1old`. A new relic then appears without touching the report. Alternative (reading `battle_relic_pool`) hides relics that cannot drop.
- **Stat total** = `bonus_atk + bonus_blk + bonus_spd`, negatives subtracting (a -1 SPEED tradeoff lowers the total). One point per stat is the roadmap's own measure.
- **Weapon average** = `amount * (sides + 1) / 2`, reported separately because dice are not stat points.
- **Budgets** are constants at the top of the script: stat total 1 / 2 / 3 for common / uncommon / rare; weapon average caps by rarity are proposed at 3.5 / 5.5 / 6.5 and are confirmed or changed when the first report is read. Mythic has no cap and is listed as "review by hand". The flag only says "above budget"; it never fails the run.
- **Statuses mentioned** come from matching the relic's `.gd` source against the ids in `statuses/*.tres`, so no per-relic annotation is needed. It is a hint, not proof.
- **Consumable** = the script source contains `consume_relic`. Keeps Phoenix Feather visible as a one-use item.
- **Output** is markdown to stdout, exit code 0 always.

## Risks / Trade-offs

- [Source matching reports a status named only in a comment] → label the column "mentions" and keep it advisory.
- [Initial weapon-average caps are a guess] → they live in one constant block and are reviewed with the first report before `item-balance-pass`.
