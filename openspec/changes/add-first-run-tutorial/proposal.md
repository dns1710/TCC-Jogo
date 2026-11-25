# Proposal

## Why

Nothing in the game explains how a fight works: the turn bar, what Attack and Block do, or that an attack needs a target click. New players have to guess. A short tutorial shown once, with a way to bring it back, fixes this without cluttering returning players' runs.

## What Changes

- A tutorial overlay of a few short pages: the turn bar, Attack and Block, how to target an enemy, and reading statuses.
- It shows automatically **once**, at the first battle the game has ever started on this machine, and never again on its own.
- A **Tutorial** button on the main menu and on the in-run pause menu shows it again on request.
- Two new signals in `Events` (`tutorial_requested`, `tutorial_finished`) and a `TutorialManager` autoload that listens to the existing `Events.battle_start` and to `tutorial_requested`. `battle.gd` is not edited.
- A tiny user settings file (`user://settings.cfg`) remembers that the tutorial was seen.

Out of scope: tutorials for shops, events, the map or relics; scripted guided fights; changing any battle rule.

## Capabilities

### New Capabilities
- `first-run-tutorial`: when the tutorial appears, what it covers, how it is dismissed and replayed.

### Modified Capabilities

None.

## Impact

- New: `scenes/tutorial/` (overlay scene and script), `global/tutorial_manager.gd` (autoload), `user://settings.cfg` at runtime.
- Edited: `global/events.gd` (2 signals), `project.godot` (autoload), `scenes/ui/main_menu.tscn` and `main_menu.gd` (button), `scenes/run/run.tscn` pause menu (button, wired in `pause_menu.gd`).
- Not edited: `scenes/battle/battle.gd`.
- Tests: new `tools/verify_tutorial.tscn`.
