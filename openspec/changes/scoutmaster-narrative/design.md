# Design

## Context

The player's journey is Main Menu, Run (map, battles, rooms), act transitions, then the win screen after Act 3. The difficulty adjustment lives in `custom_resources/dda.gd`: `decide_after_*` return `DDAConversion`s (from type, to type) and `DDA.execute` applies them through `Map.convert_rooms`; the change is then shown by `Map.play_pending_conversions`, which emits `Events.animation_dda_lock(true)` while the cosmetic room-change animation plays. The win screen is `scenes/win_screen/win_screen.tscn` (portrait plus "The %s is victorious!"). The main menu shows the title "Rogue Playing Game"; `project.godot` still has the template name. In-world text was deliberately written as serious dark fantasy and stays that way. See proposal.md for the story and scope.

## Goals / Non-Goals

**Goals:**
- Make the scout, storm and scoutmaster frame visible with the fewest words possible.
- Tie scoutmaster remarks to real difficulty changes.

**Non-Goals:**
- Dialogue trees, new characters, portraits, audio, rewriting events or act lore.

## Decisions

**1. Remarks hook into the existing DDA flow with one signal.** `DDA.execute` already knows every applied conversion. After applying, if at least one room changed it emits `Events.dda_adjusted(harder: bool)` (harder when any applied conversion has `to_type == MONSTER`, otherwise easier; if both happen in one call, harder wins). This is the single place all conversion paths go through, so `run.gd` is not edited. Alternative: emit from each `decide_*` caller in `run.gd`; rejected, three call sites and easy to miss one.

**2. Show the remark when the change is visible.** A `ScoutmasterBanner` autoload keeps the last pending direction from `dda_adjusted` and shows its line when `Events.animation_dda_lock(true)` fires (the room-change animation starting). If a new adjustment arrives before the animation, the latest direction replaces the pending one. A pending remark that never gets an animation is dropped when the next battle starts (`Events.battle_start`).

**3. Banner presentation.** A single `Label` panel at the top of a high `CanvasLayer`, prefixed "SCOUTMASTER:", fading in, staying about 3 seconds (a click dismisses it) and fading out. It uses the game's pixel font and does not take input focus, so map dragging and room clicks are unaffected. No portrait for now; the art developer can add one later through a single `TextureRect` slot.

**4. Lines live in data.** A `Resource` (`scenes/narrative/scoutmaster_lines.tres`) holds `harder`, `easier`, `opening` and `epilogue` string arrays so the text can be edited without code. Remarks choose randomly avoiding an immediate repeat.

**5. Copy (approved by the user as drafted; short and plain).**
- Harder: "Hmm... things are going too smoothly." / "Let's make this a bit more interesting." / "You look comfortable. Not for long."
- Easier: "Maybe I've been too harsh." / "Take a breather, scout." / "Fine, I'll go easy on you. Once."
- Opening (4 lines): "The rain won't stop." / "Everyone is stuck in the camp." / "Scoutmaster: 'Let's play an RPG.'" / "You roll for initiative."
- Epilogue (3 lines): "Scoutmaster: 'Alright, that's enough.'" / "'Off to bed. No chores tomorrow morning.'" / "The scout sleeps well."

**6. Opening scene.** `scenes/narrative/opening.tscn`: a dark screen, simple rain made of a few falling `Line2D` or `GPUParticles2D` streaks (no new art), lines revealed one at a time, any click or key skips to the end. Shown when starting a New Run: the main menu's new-run handler changes to the opening first and the opening then loads the run scene, so run code is untouched. Continue goes straight to the run as today.

**7. Win screen epilogue.** Add a `Label` to the win screen with the epilogue lines under the existing message; the existing victory text stays. Kept additive to ease combining with `add-run-scoring`, which will also edit this screen.

**8. Project name.** Set `config/name` in `project.godot` to "Rogue Playing Game".

## Risks / Trade-offs

- [Remarks feel repetitive] → Three lines per direction and no immediate repeats; the data file makes adding lines trivial. The copy is approved; changes after playtesting only touch the data file.
- [Remark appears at the wrong time (no animation)] → Dropped at the next battle start; the harness covers it.
- [The opening annoys returning players] → One click skips it; it is not shown on Continue. If it still annoys, limit it to the first run per machine (a one-line change using the tutorial's settings file).
- [Tone clash between the camp frame and serious in-world text] → Frame text is short and dry; in-world text is untouched.
- [Win screen conflicts with `add-run-scoring`] → Additive label only; reconcile when scoring is applied.
