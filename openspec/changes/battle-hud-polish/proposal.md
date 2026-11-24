# Proposal

## Why

The battle HUD works but is rough at 256x144: the ATTACK and BLOCK buttons are bare small text with no visible button shape, nothing shows that Attack is armed and waiting for a target (only the mouse cursor changes), and text and bars can be hard to read on bright backgrounds such as the ice stage. The request is a **small** revision: improve presentation, change nothing that already works.

## What Changes

- Make ATTACK and BLOCK read as buttons: visible shape and distinct normal, hover, pressed and disabled looks, using the existing pixel font.
- Let the **right mouse button cancel an armed attack** (nothing is used, the turn is not spent).
- Show that Attack is armed: the ATTACK button stays highlighted and a short "Pick a target" hint appears until a target is chosen or Block is used.
- Tidy spacing and alignment of the stats row (block and health), the status icon row and the turn bar circles so they sit consistently under and over fighters.
- Check text and bar contrast on the forest, ice and fire backgrounds and fix only what is hard to read (outline or shadow on labels).
- A first task captures before-screenshots and lists the specific issues found; the list is approved before any fix, so nothing is "improved" that was fine.

Out of scope (hard rule): any change to behavior, signals, node names or unique names, stats update logic, `battle_ui.gd` public behavior, ATB timing, or the map and other screens. No new mechanics beyond the requested right-click cancel.

## Capabilities

### New Capabilities
- `battle-hud`: how the battle HUD presents actions, the armed-attack state and readability.

### Modified Capabilities

None.

## Impact

- Scene and theme edits: `scenes/battle/battle.tscn` (button properties), `scenes/ui/stats_ui.tscn`, `health_ui.tscn`, `status_handler` scenes, `intent_ui` and turn bar styling as needed; optionally a small theme resource under `scenes/ui/`.
- Code: at most a few lines in `scenes/ui/battle_ui.gd` to toggle the armed-state visuals, with no change to what pressing buttons does.
- Tests: new `tools/verify_battle_hud.tscn` (behavior preserved plus new states); existing suites untouched.
