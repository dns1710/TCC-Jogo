# Design

## Context

Boss patterns follow the Bear boss (threshold actions setting `special_state`, conditional actions checking it). After the prerequisite changes, `ThresholdAction`, `SummonAction` and `TelegraphAction`/`TelegraphedStrikeAction` are available, with Scorch, Speed Up and Attack Up. The Fire Imp comes from `act3-fire-enemies`. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- A readable three-phase boss using only existing building blocks.

**Non-Goals:**
- New engine features, art, final balance.

## Decisions

**1. First-guess stats.** HP 90, attack 5, speed 4, Freeze-immune. Claw 2d6 + atk (weight 6). Fire Breath: prepare, then 3d6 + atk and Scorch x2 (weight 4 for the prepare). Gold 80 to 110. All in data.

**2. Phases by threshold actions.** Phase 2 (60%) and phase 3 (30%) are `ThresholdAction`s that set `special_state` (`PHASE2`, `PHASE3`) and perform their one-time effect (Roar; Speed Up x2). Because thresholds have priority over ordinary actions, a hit crossing both thresholds still performs the Roar first and the phase 3 action on the following action.

**3. Summon rule.** The same `SummonAction` as Krampus (cap 2, 4-action cooldown), conditional on `PHASE2` or later.

**4. Ember Field.** In `PHASE3`, the Dragon's action-completed hook applies Scorch 1 to the player; implemented as a small status or listener on the Dragon so it reads in the status row ("Ember Field").

**5. Replace the temporary tier 3.** `battles/map3/battle_stats_pool.tres` drops the two Act 1 bosses for the Fire Dragon battle.

## Risks / Trade-offs

- [Ember Field plus Breath plus imps is too much damage] → Numbers are first guesses; Scorch decays by stacks, and the balancing pass can lower Breath damage or Ember Field's stacks.
- [Roar buffs the Dragon but nothing else is alive] → Roar still applies to the Dragon itself; it gives value even alone.
- [Thresholds crossed in one hit] → Tests cover a single hit across both thresholds.
