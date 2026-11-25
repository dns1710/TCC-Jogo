# Proposal

## Why

The game has no frame. The intended story is small and clear: the game was once "Surprise Scout", then became "Rogue Playing Game", a play on RPG. A scout is at a camp when a rainstorm hits and traps everyone in. To kill time the scoutmaster proposes playing an RPG, and that is the game the player plays, which is why it is full of dice and fantasy. The scoutmaster is the game master, and the difficulty adjustment is the scoutmaster nitpicking the game ("things are going too smoothly", "maybe I have been too harsh"). Beating the game earns the scout a night's sleep and no morning duties.

Today none of this is visible. This change surfaces it with as little text as possible: the game is not meant to have much dialogue, if any, beyond scoutmaster interjections.

## What Changes

- **Opening:** a short, skippable scene at the start of a New Run (not on Continue): the rain, the camp, the scoutmaster proposing the RPG. A few lines at most, no new art (a dark screen with falling rain lines and text).
- **Scoutmaster remarks:** when the difficulty adjustment changes upcoming rooms, a one-line remark from the scoutmaster appears with the map change: a "making it harder" line or a "going easier" line.
- **Ending:** the win screen becomes a short ending sequence (about 10 seconds, skippable) that closes the frame the opening started: the victory beat, the rain stopping, the three-line scoutmaster epilogue (the game is over, the scout may sleep, no duties in the morning) and the portrait dimming as the scout falls asleep. The Main Menu button fades in at the end.
- Set the project and window name to "Rogue Playing Game" (it is still the template name "Deck Builder Tutorial").

Copy: the drafted lines (opening, remarks, epilogue) are approved as written.

Kept as is: the in-world text (24 events, act transition lore) stays serious dark fantasy; only the frame around the game is the lighter camp layer. No new characters, no branching dialogue.

Out of scope: a scoutmaster portrait (art developer, later), the loss screen, sound, event rewrites, the scout's new model, any score or leaderboard work.

## Capabilities

### New Capabilities
- `scoutmaster-narrative`: the camp frame: opening, scoutmaster remarks on difficulty changes, and the ending epilogue, with a hard limit on how much text there is.

### Modified Capabilities

None.

## Impact

- New: `scenes/narrative/` (opening scene, remark banner, shared `RainBackdrop` used by the opening and the win screen), a small text resource of the lines.
- Edited: `global/events.gd` (one new signal), `custom_resources/dda.gd` (`execute` emits it), `scenes/ui/main_menu.gd` or `scenes/run/run.gd` (show the opening on a New Run), `scenes/win_screen/win_screen.tscn` and `.gd` (rewritten as the ending sequence), `project.godot` (name).
- Tests: new `tools/verify_narrative.tscn`.
- Note: `add-run-scoring` (not applied yet) will also change the win screen. The sequence ends in one `finished` point and one exit action, so scoring only needs to change where that action leads (the score screen instead of the main menu).
