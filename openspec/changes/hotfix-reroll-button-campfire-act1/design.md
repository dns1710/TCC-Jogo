## Context

`map.gd` sets `reroll_button.disabled` only inside `_update_reroll_button()`, which runs after a room reroll and when reroll mode starts. Events change `run_stats.rerolls` (`EventOutcome`) outside the map, and `show_map()` never refreshes the button, so a button disabled at 0 stays disabled after +1. `RunStats.rerolls` is a plain exported var with no change signal. Act pools are `.tres` files referenced from `acts/*.tres`; Campfire's battle files live under `battles/map3/tier1/` with hand-written path references and no UIDs.

## Goals / Non-Goals

**Goals:** button state always matches `rerolls`; Campfire battle drawn in Act 1 tier 2, not Act 3.
**Non-Goals:** reworking reroll UX, balance changes, the unused `reroll_ui.gd`.

## Decisions

- **Refresh on `show_map()`** (call `_update_reroll_button()`), plus after `run_stats` is assigned/loaded. Minimal and covers the event flow, since events always return to the map via `show_map()`. Alternative: a `rerolls_changed` signal on `RunStats` with a setter, which is more robust but touches the saved resource and every writer; rejected for a hotfix.
- **Move the files** `tier_2_campfire.tres/.tscn` to `battles/map1/tier2/`, update their internal path, add to `battles/battle_stats_pool.tres`, and remove from `battles/map3/battle_stats_pool.tres`. Alternative: reference the map3 file from the Act 1 pool; rejected because folders are organised per act. Move with `git mv`; Godot editor may need a rescan, and `.import`/uid files for the scene must move with it.
- **Update `verify_act_enemies.gd`**: remove `campfire` from `FIRE_ENEMIES`, allow it in an Act 1 pool check; its mechanic check (`_check_campfire`) stays.

## Risks / Trade-offs

- Campfire's Spirits/summon behaviour was tuned for Act 3 → Act 1 difficulty may be off; flag in playtest, no change now.
- Act 3 tier 1 drops from 4 to 3 battles → acceptable, still non-empty.
- Saves referencing the old campfire path → saved runs store room battle stats; an in-progress Act 3 save could hold a stale path → verify load, otherwise keep a note.
