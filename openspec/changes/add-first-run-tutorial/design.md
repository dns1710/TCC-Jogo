# Design

## Context

`Battle` already emits `Events.battle_start` from `start_battle()`, so a listener can react to the first battle without touching `battle.gd`. The battle HUD is a `CanvasLayer` (`BattleUI`, group `ui_layer`) with `%AttackButton` and `%BlockButton`. The game is 256x144 with viewport stretch, so overlay text must be tiny and short. The main menu is `scenes/ui/main_menu.tscn`; the in-run pause menu is a `CanvasLayer` in `run.tscn`. There is no settings file today; only `user://savegame.tres` for runs.

## Goals / Non-Goals

**Goals:**
- A short, skippable tutorial that appears once and can be replayed, with no edits to battle logic.

**Non-Goals:**
- Interactive scripted fights, per-feature tutorials, localisation.

## Decisions

**1. Autoload `TutorialManager`.** It listens to `Events.battle_start` (auto-show) and `Events.tutorial_requested` (buttons), and adds the overlay to the current scene tree. Alternative: have `Battle` instance the overlay; rejected, the request is to not edit `battle.gd`. Alternative: instance it from `Run`; rejected, it would not cover a battle started outside `Run` and couples the tutorial to run code.

**2. New signals.** `Events.tutorial_requested` (any scene asks for it) and `Events.tutorial_finished` (overlay closed; lets menus restore focus). Buttons only emit the signal and never reference the manager.

**3. Persistence.** A `ConfigFile` at `user://settings.cfg`, section `tutorial`, key `seen`. Read at startup, written when the overlay closes. In-memory `_shown_this_session` backs it up so an unwritable file cannot cause nagging. Because the flag is per machine and not per save, existing players see the tutorial once on their next first battle; accepted and cheap to dismiss.

**4. Overlay.** A `CanvasLayer` at a high layer with `process_mode = ALWAYS`, a dim `ColorRect`, a panel with the page text and Back / Next / Skip buttons, and a "page n/m" label. It sets `get_tree().paused = true` when it opens and restores the previous paused state on close (the pause menu may already be paused). When the battle UI exists, pages 2 and 3 pulse a highlight frame around the Attack and Block buttons (found through the `ui_layer` group and their unique names); with no battle (main menu) the highlight is skipped and the text still reads on its own.

**5. Draft page copy (for review; short and plain).**
1. "TURN BAR: The bar beside each fighter fills over time. When yours is full, it is your turn."
2. "ATTACK: Press ATTACK, then click an enemy to hit it."
3. "BLOCK: Press BLOCK to gain block. Block absorbs damage before health."
4. "ENEMIES ACT TOO: When an enemy's bar fills, it acts. Kill them all to win."
5. "STATUSES: Icons under a fighter are statuses. Hover or click one to read what it does."

**6. Buttons.** A `TUTORIAL` button on the main menu list (between New Run and Exit) and one on the pause menu beside Back to Game. The pause menu button is connected in `pause_menu.gd` (which already owns that menu) to emit `Events.tutorial_requested`; `run.gd` is not touched.

## Risks / Trade-offs

- [Overlay opens while another dialog already paused the tree] → Remember and restore the previous `paused` value instead of forcing `false`.
- [The pause menu gets covered or the overlay sits under it] → Use a layer above the pause menu and verify by screenshot.
- [Text too small to read at 256x144] → Use the game's pixel font at its existing sizes and verify at the real window scale.
- [`battle_start` fires twice or in a non-run scene] → The manager ignores it once seen or once shown this session.
