# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import. Screenshots: temporary scene in `tools/` run non-headless, deleted afterwards.

## 1. Baseline and issue list

- [x] 1.1 Capture before-screenshots of a battle on the forest, ice and fire backgrounds (player turn ready, attack armed, with statuses and block shown) and write the concrete list of readability and alignment issues. Verify: the list is shown to the user and approved or trimmed before any fix; nothing outside the list is changed.

## 2. Test harness

- [x] 2.1 Add `tools/verify_battle_hud.tscn` and script: buttons disabled when the player cannot act and enabled when it can, attack then enemy click applies the attack, block applies block, armed highlight and hint appear and clear as specified, right click cancels an armed attack. Verify: the behavior checks pass on the current code and the armed-state checks fail until implemented.

## 3. Changes

- [x] 3.1 Style ATTACK and BLOCK (normal, hover, pressed, disabled). Verify: screenshots show all four looks; node names and unique names are unchanged.
- [x] 3.2 Armed-attack highlight and "Pick a target" hint. Verify: the harness covers arm, use, and switching to block.
- [x] 3.3 Right mouse button cancels an armed attack. Verify: the harness covers cancel while armed (cursor, highlight and hint cleared, `can_act` still true, no action used, no `player_action_completed`), and right click with nothing armed does nothing.
- [x] 3.4 Fix only the approved spacing, alignment and contrast items. Verify: before and after screenshots on all three backgrounds show each listed item fixed and nothing else different.

## 4. Integration

- [x] 4.1 Boot check and all suites. Verify: no script errors, every suite exits 0, and `git diff` shows no change to battle, ATB, effects or enemy scripts.
- [ ] 4.2 Manual playtest of one fight per background. Left to the user.

## Workflow follow-up

- Archive after review so `battle-hud` becomes a main spec.
