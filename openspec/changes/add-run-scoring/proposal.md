# Proposal

## Why

The game has no score. A leaderboard prototype exists on the unmerged `origin/BranchAPI` branch (a Supabase service, a leaderboard scene and a points autoload), but it scores only rooms, gold and victory, is not saved (Continue resets it to 0), names every player `"Player - <timestamp>"`, only submits on death and victory, and overwrites by name with the public key. We want a rich score the player can see being built, submitted for wins and losses, under a name the player chose.

## What Changes

- Track a saved per-run score breakdown: rooms cleared, elites and bosses defeated, acts cleared, flawless and high-health fights, gold held at the end, relics by rarity, events completed, victory bonus.
- Multiply fight and room points by a difficulty factor from the difficulty (DDA) score at the time (0.75 at score 0, linear to 1.5 at score 100).
- Show a score screen at the end of every run, win or loss, listing each category, its count, its points and the multiplier, and the total.
- Ask for a player name before a new run starts, save it with the run, and submit the final score under it. Losses submit what was earned.
- Port the leaderboard and submission service from `BranchAPI` by copying files (not merging the branch), submit by inserting a row per run, and show best score per name.
- Point values live in a tunable resource; the initial values are placeholders to balance later.

Out of scope: tuning final point values; the Supabase table and row-level-security setup (done by the project owner on the dashboard); anti-cheat beyond what the above gives.

## Capabilities

### New Capabilities
- `run-scoring`: how a run's score is earned, shown and recorded.
- `leaderboard`: how final scores are submitted under a player name and displayed.

### Modified Capabilities

None.

## Impact

- Code: new `RunScore` resource and config, score screen scene, name input on the pre-run flow (`main_menu` / `character_selector`, `RunStartup`), hooks in `run.gd` and `battle.gd`, `SaveGame`, `win_screen`, `battle_over_panel` (loss path), ported `supabase_service.gd` and leaderboard scenes, `project.godot` autoload.
- Files copied from `origin/BranchAPI`: `global/supabase_service.gd`, `scenes/ui/leaderboard*.tscn/.gd`.
- Depends on `add-act-framework` (act-cleared points) and uses the DDA score from `rework-dda-flags` only as a read.
