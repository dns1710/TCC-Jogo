# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import.

## 1. Test harness first

- [x] 1.1 Add `tools/verify_tutorial.tscn` and script covering: unseen flag shows on `battle_start`, seen flag does not, skip records seen, replay via `tutorial_requested` works when seen, the tree is paused while open and restored afterwards, an unwritable settings path still limits to one automatic show per session, page count at most 5. It must back up and restore `user://settings.cfg`. Verify: it fails before the manager exists.

## 2. Core

- [x] 2.1 Add the two `Events` signals and the `TutorialManager` autoload with the settings file logic. Verify: the flag tests of the harness pass.
- [x] 2.2 Build `scenes/tutorial/tutorial_overlay.tscn` and script (pages, Back/Next/Skip, page counter, pause and restore, highlight of Attack and Block when present). Verify: the harness opens it, steps through the pages and closes it.

## 3. Entry points

- [x] 3.1 Add the Tutorial button to the main menu. Verify: pressing it shows the overlay without a battle and closing returns to the menu.
- [x] 3.2 Add the Tutorial button to the pause menu (wired in `pause_menu.gd`). Verify: in a battle the overlay appears above the pause menu and closing it returns to the pause menu.

## 4. Integration

- [x] 4.1 Boot check and all suites. Verify: no script errors and every suite exits 0 (`verify_tutorial` plus the existing ones), and `battle.gd` is unchanged in the diff.
- [x] 4.2 Look at rendered screenshots of each page on the battle and on the main menu at real scale. Verify: text is readable and nothing overlaps.
- [ ] 4.3 Manual playtest: fresh settings file, first battle shows it once, second battle and a restart do not, the menu button shows it again. Left to the user.

## Workflow follow-up

- Archive after review so `first-run-tutorial` becomes a main spec.
