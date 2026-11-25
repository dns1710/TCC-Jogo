# Design

## Context

Boss patterns already exist in `enemies/bear_boss` (a wake action and an enrage action behind an HP threshold) and `big_chicken_boss`. After the prerequisite changes, `ThresholdAction`, `SummonAction`, `TelegraphAction`/`TelegraphedStrikeAction` and `HealAlliesAction` are available, along with Freeze, Brittle and Speed Down. The Snow Wolf pup comes from `act2-ice-enemies`. Act 1 bosses are 40 to 60 HP. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- A readable three-phase boss that uses only existing building blocks.

**Non-Goals:**
- New engine features, art, final balance.

## Decisions

**1. First-guess stats.** HP 90, attack 4, speed 4, Freeze-immune. Birch Switch: two hits of 1d4 + atk (weight 6). Chain Pull: Speed Down x3 and Brittle (weight 4). Winter's Wrath: prepare, then 3d8 + atk and a short Freeze. Gold 80 to 110. All in data.

**2. Phases by threshold actions, not a state machine.** Phase 2 and 3 are `ThresholdAction`s (once each at 50% and 25%) that set `special_state` (`PHASE2`, `PHASE3`); conditional actions check the state. Phase 3's Speed Up is applied by the phase 3 threshold action. This reuses the Bear boss pattern.

**3. Summon rule.** A `SummonAction` limited by alive count (2) and a 3-action cooldown, conditional on `PHASE2` or later. Alternative: summon once; rejected, respawning wolves keep pressure after the player clears them.

**4. Wrath cadence.** A counter of Krampus's own actions makes every third action Winter's Wrath in phase 3, as a conditional prepare action followed by the strike (the strike requires the prepare state, like the Bomb).

**5. Replace the temporary tier 3.** `battles/map2/battle_stats_pool.tres` drops the two Act 1 bosses for the Krampus battle.

## Risks / Trade-offs

- [Freeze from Winter's Wrath feels bad] → It is short, telegraphed, and the player has a full bar to react (for example by blocking); numbers are tunable.
- [Wolves plus Chain Pull plus Wrath overwhelm] → Cap of 2 wolves and a 3-action cooldown; balancing pass may lower damage.
- [Thresholds crossed in one hit (jump from above 50% to below 25%)] → Both phase actions are performable in order; tests cover a big hit across both thresholds.
