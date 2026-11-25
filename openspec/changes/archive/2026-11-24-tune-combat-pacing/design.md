# Design

## Context

`Player.add_atb` and `Enemy.add_atb` do `atb += stats.speed * delta` up to a duplicated `ATB_MAX := 30.0`. `Stats.speed` is an int clamped to 1..20; `SpeedDownStatus` subtracts its stack count from it, permanently (it never sets `can_expire`). Enemy base speeds are 3 (Cap, Croc, Bear Boss), 4 (Zscout, Bomb), 6 (Chicken), 7 (Onca); the player is 5, and the starter armor takes 2. `ATBManager.start_battle` gives the player 15 (50%) and each enemy 0 to 10. `RELIC_APPLY_INTERVAL` is 0.5 seconds per relic per phase. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Faster base pace and a slow that scales smoothly at every base speed.
- Everything tunable from one constant plus one factor, so the parry mechanic can retune pace later.

**Non-Goals:**
- Changing speed stats, Speed Up behavior, or adding buffs.

## Decisions

**1. Shared `ATB_MAX = 20`** in one script both actors read. Scaling only time, it does not change relative speeds. Start values scale: player 50%, enemies 0 to 6.7 (same 0 to 33% share).

**2. Slow becomes a rate multiplier, not a stat change.** Add `atb_rate_multiplier` on actors (default 1.0); `add_atb` uses `speed * multiplier * delta`. The Speed Down status sets it to `0.85 ^ stacks`. The integer `speed` stat is untouched, so relics that read speed (Needle, Red Mantle) keep working, and no rounding of small speeds is needed. Alternative: apply percentages to the integer stat; rejected, 15% of 3 rounds to nothing.

**3. Decay by action.** Speed Down keeps intensity stacks and, when its owner completes an action, drops one stack and removes itself at zero. Reuses the existing stack and status UI. Alternative: duration stack type; rejected because it cannot also stack in intensity.

**4. Suggested balance (tunable):** 0.85 per stack, one stack per Icy hit, one stack per Croc grab. A single hit slows about 15% for one action; stacking several hits in one turn gives a bigger slow lasting that many actions. Re-evaluate after playtests with the 20 bar.

**5. Relic wait cap.** Interval becomes `min(0.25, 1.5 / relic_count)`.

## Risks / Trade-offs

- [20 may feel too fast once the parry mechanic exists] → The constant is in one place; revisit then (the request already anticipates this).
- [Percent slow plus Icy hit on multi-enemy fights stacks quickly] → Decay by action bounds it; watch it in Act 2's Ice content.
- [Starter armor's −2 speed still makes the player slower than enemies] → Left as is for now; reassess after the faster bar.
- [Playtest result] An ATB requirement of 20 felt good in playtesting, so it stays. Follow-up request: the Croc's opening grab applies 2 Speed Down stacks and each later regular hit has a 15% chance to add 1 more (both tunable on the action nodes).
