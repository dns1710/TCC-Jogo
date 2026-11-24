# Proposal

## Why

Events are drawn with `Array.pick_random()` when the map is generated, ignoring the seeded run RNG, so a player can meet the same event repeatedly and a branch they never visit can hold duplicates. The pool has two hand-built events, each a bespoke scene and script, and pressing a button sends the player straight back to the map with no feedback, so a gamble shows nothing. Events are now per act (Forest, Ice, Fire), need at least 6 events per act with no repeats inside an act, and need to be cheap to add.

## What Changes

- Add a data-driven event system: an event is a resource (title, text, choices); a choice has costs, an optional stat check and weighted outcomes; an outcome has text and effects (gold, HP, max HP, attack, block, speed, rerolls, difficulty score, a random relic, converting an upcoming room). One reusable scene runs any event; a custom scene can still be attached for special cases.
- Every event shows an outcome screen after the choice: what happened, the effects as lines (for example "+45 gold", "-8 HP"), and a Continue button.
- Events can reach the relic handler, the map and the relic reward pool, enabling relic and room-change effects.
- Choose an event when the player enters an event room, from the current act's own pool, excluding events already seen in this act; seen events are saved and reset each act; the seeded run RNG is used.
- Lower the event room share from 25% to 18% of randomly typed rooms (battles absorb the difference).
- Ship 24 events: 8 for each act (6 core plus 2 spare), in a serious dark-fantasy tone with light folklore touches (no meme humor); port the Slot Machine and Marshmallow to the new system as the Gambler's Stump and Abandoned Supplies.

Out of scope: art and sound for events, DDA effects beyond the existing score deltas, a visual event editor.

## Capabilities

### New Capabilities
- `event-rooms`: how event rooms pick their event, how an event plays out and reports its result, what an event can do, and how often event rooms appear.

### Modified Capabilities

None.

## Impact

- Code: `custom_resources/event_room_pool.gd` (pool of definitions), new event resource scripts and `scenes/event_rooms/choice_event.*`, `scenes/event_rooms/event_room.gd`, `scenes/run/run.gd` (`_on_event_room_entered`, act reset), `scenes/map/map_generator.gd` and `map.gd` (no event assignment, new odds), `custom_resources/run_stats.gd` (seen events), act resources (own event pools), removal of the old gamble and marshmallow scripts and scenes.
- New content: 3 event pools and 24 event resources.
- Depends on `add-act-framework` (merged). Independent of `rework-dda-flags`, which may later route the difficulty-score deltas.
