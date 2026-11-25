# Design

## Context

`Player` and `Enemy` each keep an `atb_rate_multiplier` that `SpeedDownStatus` overwrites with `0.85 ^ stacks` and that `add_atb` multiplies in. Statuses are `Status` resources; the status handler stacks intensity or duration, and `END_OF_TURN` statuses tick after an enemy finishes an action (and after the player's, through relic events). Damage to either actor goes through `take_damage`, which applies the `DMG_TAKEN` modifier then calls `stats.take_damage` (block first). Block is gained through `BlockEffect`, which adds to `stats.block` directly. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- A small, tested set of statuses both sides can use; no behavior change to existing Speed Down.

**Non-Goals:**
- Any enemy content; changing existing statuses' numbers.

## Decisions

**1. Rate modifiers by source in one shared component.** A small `ATBModifiers` helper holds `{source: factor}`; `atb_rate_multiplier` becomes the product so existing code (`add_atb`, `verify_combat_pacing`) keeps working. Speed Down uses source `"speed_down"`, Freeze `"freeze"`. Alternative: add a second multiplier field per effect; rejected, it does not scale to the next effect.

**2. Freeze time lives in `add_atb`.** `add_atb(delta)` is only called while the battle runs, so freeze and immunity are measured in battle time and pause with it. Freeze sets the `"freeze"` factor to 0 and counts down; on expiry it starts the immunity timer. Immunity is a flag on the actor (`freeze_immune`) so bosses can opt out permanently.

**3. Brittle through the existing damage modifier.** On apply it adds a `DMG_TAKEN` percent value (source `"brittle"`, +0.5), the same mechanism the old Exposed status used. A new `damage_received` signal on both actors tells the status to remove itself after the first hit. Alternative: a special-case check inside `take_damage`; rejected, a signal keeps statuses self-contained.

**4. Scorch as an `END_OF_TURN` intensity status.** It deals `stacks` damage and removes one stack on each tick, like Burn but scaling with stacks.

**5. Ashen via a block-gain multiplier.** Actors expose `block_gain_multiplier` (default 1.0) read by `BlockEffect`; Ashen sets 0.5 and removes it when its 3-action duration ends.

**6. Sunder as a one-shot flag.** `take_damage` reads and clears `ignore_block_next_hit`; Sunder sets it. The block stays intact, the hit goes straight to health.

**7. Placeholder icons.** Existing 10x10 status icons are recolored by a one-off script into `art/arte nao tao verdadeira/status_*.png` (names are final-art filenames with a `_placeholder` suffix), so replacing art later is a file swap.

## Risks / Trade-offs

- [Refactoring the rate breaks Speed Down] → `verify_combat_pacing` must pass unchanged, plus new tests for combined slows.
- [Freeze feels bad on the player] → It is short, never chains, and bosses are immune; enemies that apply it should use it sparingly (see the enemy changes).
- [`take_damage` hooks touch both actors] → Keep the hooks small and covered by tests on both Player and Enemy.
- [Placeholder icons confuse testers] → Distinct colors per status, and the art list names the final files.
