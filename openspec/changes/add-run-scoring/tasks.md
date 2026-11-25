# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`.

## 1. Score model

- [ ] 1.1 Add `ScoreConfig` (placeholder values from the design) and `RunScore` (counters, `award(category, base_points, difficulty_score)`, `total()`, breakdown lines) on `RunStats`, saved in `SaveGame`. Verify: a headless scene awards one room at difficulty 100 and 0 and asserts 15 and 7.5 base-adjusted points, and a save/load round trip keeps the counters.
- [ ] 1.2 Hook awards: room cleared, elite and boss defeat, act cleared (from `add-act-framework`), flawless and 75%+ finishes, event completed, relic ownership and gold held at run end, victory bonus. Verify: a scripted run through battle win, event and boss shows each counter incrementing once.

## 2. Name and screen

- [ ] 2.1 Add the name field (1 to 16 characters) to the character selector, carry it via `RunStartup` into `RunStats.player_name`, block Start when empty. Verify: empty name keeps the Start button inactive or shows the highlight, and the name appears in the saved run after Continue.
- [ ] 2.2 Add the score screen listing category, count, points, multiplier and total; open it from `win_screen` and from the `BattleOverPanel` loss action, then return to the main menu. Verify: a forced loss in Act 1 and a forced victory both show the breakdown with no victory bonus on the loss.

## 3. Leaderboard

- [ ] 3.1 Copy `supabase_service.gd` and the leaderboard scenes from `origin/BranchAPI`, register the autoload, change submission to insert-only with a timeout, show best score per name, and add the main-menu button. Verify: boot check shows no script errors and the leaderboard opens; with the network disabled it shows the error label.
- [ ] 3.2 Submit on both run endings from the score screen and show "could not submit" on failure. Verify: with the network disabled the screen still returns to the main menu; with it enabled a row appears for the entered name. Project owner confirms the Supabase table permits insert and select only.

## 4. Integration

- [ ] 4.1 Play one run to defeat and one to victory, with a save/continue in between. Verify: both submit under the chosen name and the totals equal the sum of the screen's lines.
