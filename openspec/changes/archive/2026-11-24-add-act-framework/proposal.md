# Proposal

## Why

A run is one 14-floor map with one hardcoded battle pool, event pool and background, and it ends at the first boss. The planned game is three acts (Forest, Ice, Fire), each with its own enemies, events, boss, background and lore. Nothing in the run flow, save data or pool lookups knows what an act is, so every act-based feature (events, scoring, DDA resets, new content) is blocked on this.

## What Changes

- Add an `Act` definition (name, battle pool, event pool, background, transition lore) and an ordered list of three acts for a run.
- Generate each act's map from that act's pools; dynamic room changes (reroll, DDA conversions, tier-2 upgrades) read the current act's pools.
- After an act's boss is beaten: show a lore transition screen, fully heal the player, and generate the next act's map. Beating the last act's boss goes to the win screen.
- Gold, relics and rerolls carry over between acts.
- The first-battle weapon and gear reward only applies to Act 1; later acts' first room gives a normal tier-0 reward.
- Save and Continue remember the current act. Existing saves load as Act 1.
- Acts 2 and 3 ship pointing at placeholder pools (Act 1 content) until their content lands.

Out of scope: writing Act 2/3 enemies, events, art or lore text; DDA flag reset (see `rework-dda-flags`); score tracking (see `add-run-scoring`); shop price balancing across acts.

## Capabilities

### New Capabilities
- `act-progression`: a run is an ordered sequence of acts, each with its own content pools, boss and transition, with carry-over and save rules.

### Modified Capabilities

None. The `map-generation` spec (from `fix-map-generator-merge`) is unaffected: every act's map keeps the same layout and guarantees.

## Impact

- Code: `scenes/run/run.gd`, `scenes/map/map.gd`, `scenes/map/map_generator.gd`, `custom_resources/save_game.gd`, `scenes/win_screen/`; new `custom_resources/act.gd`, act resources and a transition scene.
- Depends on: `fix-map-generator-merge` being applied first (it restores the generator this change extends).
- Other changes build on this: `rework-dda-flags`, `act-event-rooms`, `add-run-scoring`.
