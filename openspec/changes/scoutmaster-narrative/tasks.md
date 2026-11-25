# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import. Screenshots: temporary scene in `tools/` run non-headless, deleted afterwards.

## 1. Test harness first

- [x] 1.1 Add `tools/verify_narrative.tscn` and script: `DDA.execute` emits `dda_adjusted` with the right direction (harder for a conversion to a battle, easier otherwise) and emits nothing when no room changed; the banner shows a harder or easier line on `animation_dda_lock(true)`, shows none without a pending remark, never repeats a line twice in a row, never exceeds one line, and drops a stale remark at `battle_start`; the opening is shown for a New Run, skipped by input, and not shown for Continue; the win screen sequence ends with the rain stopped, the epilogue (at most 3 lines) shown, the portrait dimmed and the exit button visible, `skip()` reaches that same end state at any point and the button is hidden before it only while the sequence runs, and `finished` is emitted once; opening has at most 4 lines. Verify: it fails before implementation.

## 2. Implementation

- [x] 2.1 Add `Events.dda_adjusted` and emit it from `DDA.execute`. Verify: the harness signal checks pass and `verify_dda` still passes.
- [x] 2.2 Add the lines resource and the `ScoutmasterBanner` autoload (queue, show on animation start, fade, click to dismiss, no repeats). Verify: the harness banner checks pass and map dragging still works while a remark is visible.
- [x] 2.3 Build the shared `RainBackdrop` (with `stop_rain()`), then the opening scene (rain, line reveal, skip) and route New Run through it. Verify: the harness covers New Run and Continue; the scene is readable in a screenshot.
- [x] 2.4 Rewrite the win screen as the ending sequence (rain, fade to night, epilogue reveal, portrait dim, button fade-in, skip, `finished`). Verify: the harness sequence checks pass and screenshots at the start, middle and end show no overlap between the victory text, the epilogue and the button.
- [x] 2.5 Set the project name to "Rogue Playing Game". Verify: `project.godot` shows it and the window title matches.

## 3. Integration

- [x] 3.1 Boot check and all suites. Verify: no script errors and every suite exits 0.
- [x] 3.2 Copy review: the user approved the drafted lines as written (design decision 5). Any later wording change only edits the lines data file.
- [ ] 3.3 Manual playtest: new run opening, a remark after a difficulty change, a win. Left to the user.

## Workflow follow-up

- Archive after review so `scoutmaster-narrative` becomes a main spec.
