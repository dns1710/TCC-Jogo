# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import. Screenshots: temporary scene in `tools/` run non-headless, deleted afterwards.

## 1. Test harness first

- [ ] 1.1 Add `tools/verify_narrative.tscn` and script: `DDA.execute` emits `dda_adjusted` with the right direction (harder for a conversion to a battle, easier otherwise) and emits nothing when no room changed; the banner shows a harder or easier line on `animation_dda_lock(true)`, shows none without a pending remark, never repeats a line twice in a row, never exceeds one line, and drops a stale remark at `battle_start`; the opening is shown for a New Run, skipped by input, and not shown for Continue; the win screen epilogue has at most 3 lines; opening has at most 4. Verify: it fails before implementation.

## 2. Implementation

- [ ] 2.1 Add `Events.dda_adjusted` and emit it from `DDA.execute`. Verify: the harness signal checks pass and `verify_dda` still passes.
- [ ] 2.2 Add the lines resource and the `ScoutmasterBanner` autoload (queue, show on animation start, fade, click to dismiss, no repeats). Verify: the harness banner checks pass and map dragging still works while a remark is visible.
- [ ] 2.3 Build the opening scene (rain, line reveal, skip) and route New Run through it. Verify: the harness covers New Run and Continue; the scene is readable in a screenshot.
- [ ] 2.4 Add the epilogue to the win screen. Verify: the win screen screenshot shows the victory text and the epilogue without overlap.
- [ ] 2.5 Set the project name to "Rogue Playing Game". Verify: `project.godot` shows it and the window title matches.

## 3. Integration

- [ ] 3.1 Boot check and all suites. Verify: no script errors and every suite exits 0.
- [x] 3.2 Copy review: the user approved the drafted lines as written (design decision 5). Any later wording change only edits the lines data file.
- [ ] 3.3 Manual playtest: new run opening, a remark after a difficulty change, a win. Left to the user.

## Workflow follow-up

- Archive after review so `scoutmaster-narrative` becomes a main spec.
