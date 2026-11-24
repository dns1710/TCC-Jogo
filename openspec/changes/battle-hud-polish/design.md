# Design

## Context

`BattleUI` (a `CanvasLayer` in `battle.tscn`) owns `%AttackButton` and `%BlockButton` (font size 6, bare `Button`s). `_process` disables them while `player.can_act` is false. Attack arms `pending_action` and swaps the mouse cursor; an `enemy_selected` event consumes it. Fighters show a `StatsUI` row (block and health) and a `StatusHandler` icon grid; each has a turn bar `TextureProgressBar`. The viewport is 256x144 with integer scaling, so every element is a few pixels. See proposal.md for scope and the "do not change what works" rule.

## Goals / Non-Goals

**Goals:**
- Clearer buttons, an armed-attack cue, consistent spacing, legible text on all backgrounds.

**Non-Goals:**
- New mechanics, layout redesign, other screens, anything that alters battle logic.

## Decisions

**1. Gate the work on an approved issue list.** Task 1 captures screenshots of battles on the forest, ice and fire backgrounds and writes the concrete issues found. Fixes only address listed items, so "improve" cannot drift into changing what works. The list is shown to the user before task 2 starts.

**2. Buttons via StyleBoxes on the existing nodes.** Set `theme_override_styles` (normal, hover, pressed, disabled) on the two buttons, or one small shared theme, keeping node names and unique names so `battle_ui.gd` lookups keep working. Pixel-style flat boxes with the existing outline color.

**3. Armed state is presentation only.** `battle_ui.gd` already knows `pending_action`; add one `_update_armed_visuals()` that sets the ATTACK button's pressed look (`button_pressed` style or a modulate) and shows a small `Label` ("Pick a target") above the buttons. It is called where `pending_action` is set or cleared and does not alter what those handlers do.

**4. Right mouse button cancels.** The project already defines a `right_mouse` input action that no script uses. `BattleUI` handles it in `_unhandled_input`: when `pending_action` is set, clear it, restore the default cursor and call the same `_update_armed_visuals()`; otherwise ignore the event. It consumes the event with `get_viewport().set_input_as_handled()` only when it cancelled something. Because `use_action` was never called, no action completes and the turn bar stays full.

**5. Spacing through scene properties.** Separation, offsets and alignment of the stats and status rows are adjusted in their scenes. No script changes in `stats_ui.gd`, `health_ui.gd` or the status handler.

**6. Contrast with label outline or shadow.** Use `font_outline_color` and `outline_size` (or a drop shadow) on HUD labels instead of changing colors of backgrounds. A faint dark backing strip behind the button row is allowed if outline alone is not enough on the ice background.

## Risks / Trade-offs

- [Unseen regressions in a "small" change] → `verify_battle_hud` asserts button states and that attack and block still apply; the full suite list must stay green; before and after screenshots compared.
- [Hint label hides an enemy or its bar] → Place it with the buttons at the bottom left, away from the enemy zone (x 148 to 211, y 47 to 100).
- [Styles break at other aspect ratios] → Keep anchors and sizes as they are; only visual properties change.
