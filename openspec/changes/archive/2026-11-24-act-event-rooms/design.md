# Design

## Context

Events are `PackedScene`s in one pool, each a bespoke script. `MapGenerator._assign_random_type` and two paths in `map.gd` store `room.event_scene` at generation or change time via `pick_random()`, not the seeded `RNG`. `EventRoomButton` runs a callback and immediately emits `event_room_exited`, so nothing is shown after a choice. `Run._on_event_room_entered` injects only `character_stats` and `run_stats`. A simulation of the generator gave a mean of 7.5 event rooms per map and 2.5 on one path (about 10 candidate floors). Economy anchors: a relic costs 90 to 120 gold, battles pay 60 to 100, a campfire heals 12 of 40 HP, Marshmallow gives +5 max HP. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- No repeats per act on the player's path, reproducible from saves.
- Adding an event is writing data, not code; every event reports its result.

**Non-Goals:**
- Event art and sound, a visual editor, retuning DDA.

## Decisions

**1. Events are `EventDefinition` resources; one `ChoiceEvent` scene plays any of them.** Definition: title, text, choices, optional `custom_scene` for special cases. `EventChoice`: label, `cost_gold`, `cost_hp`, `cost_rerolls`, `all_in`, optional stat check (stat, base chance, chance per point), outcomes. `EventOutcome`: weight, text, and effects (gold, a bet multiplier for all-in, hp, hp as a share of max, max hp, attack, block, speed, rerolls, difficulty delta, random relic rarity, room conversion). Alternative: one scene and script per event (today); rejected, it is what makes events expensive.

**2. Pool holds definitions; seen events are identified by resource path.** `EventRoomPool.pick(seen)` returns an unseen definition via the `RNG` autoload, falling back to a repeat with a warning. `RunStats.seen_events` (saved) is cleared at the start of each act. Rooms no longer carry an event; `Room.event_scene` stays only for save compatibility and is always null.

**3. Choose at entry, not generation.** Duplicates on unvisited branches are harmless and a map-wide rule would need about 13 events per act.

**4. Outcome screen is part of `ChoiceEvent`.** On a pick it applies costs, resolves the outcome, applies effects, and swaps to a result view (text, effect lines, Continue). Continue emits `event_room_exited`. Effect lines are generated from the effects that actually changed, so authors write only the story text.

**5. Hooks by injection.** `EventRoom` gains `relic_handler`, `map` and `relic_pool`, set where `run.gd` already sets stats. Random relics reuse the reward rules (not owned, can appear as reward, requested rarity). Room conversion calls the existing `map.change_room` without waiting for it, as the DDA code does.

**6. Safety rules.** Health effects clamp to at least 1; gold and rerolls to at least 0; attack, speed and max health keep their minimums. Choices disable themselves when unaffordable.

**7. Frequency by re-cutting the roll bands** in `_assign_random_type`: 57% battle, 18% event, 8% campfire, 10% shop, 7% treasure.

**8. Content: 8 events per act** built from six archetypes (gamble, gift, stat shop, pact, stat check, story). Balance anchors: about 50 gold per stat point (attack 70, speed 55, block 45), gifts around +4 to +8 max HP, risky heals 8 to 12 HP. Tone is serious and grounded (dark fantasy, light folklore touches), with no meme humor.

## Risks / Trade-offs

- [Outcome screen text too long for a 256x144 screen] → Labels autowrap and texts are kept short; a validation test caps body and outcome length.
- [Room conversion animation delays input after the event] → Same behavior as DDA conversions today; `rework-dda-flags` makes it instant.
- [Content balance is a first guess] → All numbers are data in `.tres` files, retunable without code.
- [Resource path changes break seen lists] → Only matters within a run; noted for the content workflow.
