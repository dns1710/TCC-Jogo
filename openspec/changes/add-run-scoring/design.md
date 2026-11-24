# Design

## Context

Nothing scores today. `origin/BranchAPI` (June 2026) has `global/score.gd` (+10 per room, +gold, +100 victory, submitted on `player_died` as `"Player - <timestamp>"`), `global/supabase_service.gd` (insert, or patch by name if higher, with the anon key in the file), a leaderboard scene and a main-menu button. Its base is older than current `main`, so it conflicts in `run.gd`, `battle.gd` and `project.godot`. `SaveGame` and `RunStats` are the natural places for per-run state; `RunStartup` carries data from the menu into the run. `win_screen` ends the run on victory; `BattleOverPanel` sends a loss straight to the main menu.

## Goals / Non-Goals

**Goals:**
- A rich, explainable, persisted score; one name per run; every ending shows the breakdown.
- Reuse the BranchAPI work without merging a stale branch.

**Non-Goals:**
- Cheat-proof scoring, account systems, final point balancing.

## Decisions

**1. `RunScore` resource on `RunStats`.** Holds counters per category (not raw points), so the screen can show count × value × multiplier and values can be retuned. Points are computed from counters plus a `ScoreConfig` resource. Alternative: autoload with a running total (BranchAPI); rejected, it cannot show a breakdown and was not saved.

**2. Multiplier is recorded per event.** Each scoring call adds its base points and the multiplier at that moment, so the displayed total equals the sum of what was awarded; the multiplier shown is the weighted average for the category.

**3. Copy BranchAPI files rather than merge.** Take `supabase_service.gd` and the leaderboard scenes, adapt to the new flow, drop its `Score` autoload and its `run.gd`/`battle.gd` edits.

**4. Insert one row per run; leaderboard reduces to best per name client-side.** The BranchAPI approach patched existing rows, which needs the public key to be allowed to update, so anyone could overwrite anyone. Insert-only needs only insert and select rights. Alternative: keep update-by-name; rejected for that exposure.

**5. Name input on the pre-run screen** (character selector, before Start) stored on `RunStats.player_name` via `RunStartup`, so it is saved with the run and continues correctly.

**6. Loss goes through the score screen.** `BattleOverPanel`'s loss action opens the score screen (which submits), then the main menu. Victory does the same from `win_screen`.

**7. Defaults for the placeholder values:** room 10, elite +15, boss +75, act cleared +100, victory +250, flawless fight +20, finish at 75% health or more +10, gold held 0.25 per gold, relics common 5 / uncommon 15 / rare 30 / mythic 60, event completed +10.

## Risks / Trade-offs

- [The Supabase key is in the repository] → Supabase anon keys are meant to be public only with row-level security; a task checks the table policy allows insert and select only, done by the project owner on the dashboard.
- [Score screen blocked by a slow request] → Submit asynchronously with a timeout and show status text.
- [Name collisions let one person's best hide another's] → Accepted for a thesis demo; noted in the leaderboard spec as best-per-name.
- [The multiplier rewards players DDA already considers strong] → Intended per the design request; values live in `ScoreConfig`.
