# Design

## Context

Current state, from reading `run.gd`, `dda.gd`, `map.gd`: `dda.gd` only updates the score; the conversion rules live in `_show_map`, `_prepare_battle`, `_on_campfire_exited`, `_on_shop_exited` and `_on_battle_won` with thresholds 15/30/35/55/65/70/75 inline. Flags (`dda_shop_changed`, `dda_treasure_pending`, `dda_treasure_spawned`, `shop_entered_items`) live on `Run` and are copied to `SaveGame` by hand; `dda_treasure_spawned` is never read. `change_room` is a coroutine whose type mutation happens after about 2s of tweening, and callers do not await it. `_on_shop_exited` calls `_show_map()` (which saves) before converting. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- One decision point, tunable numbers, correct flag lifetime, deterministic saves.
- Preserve current threshold values so behavior only changes where it was a bug.

**Non-Goals:**
- Retuning thresholds; new conversion kinds.

## Decisions

**1. DDA returns decisions; the run executes them.** Methods like `on_battle_won(...)` return a list of `{from_type, to_type}` conversions. `run.gd` applies them through the map. Alternative: let DDA call the map directly; rejected, it would couple a plain `RefCounted` to scene code and make it untestable.

**2. Thresholds in a `DDAConfig` resource**, loaded once, with the current numbers as defaults. Lets tuning happen without editing code.

**3. Flags move into a saved `DDAState` resource** (carried on `RunStats`), replacing the four loose fields. Reset via one `reset_for_act()`. Dropping `dda_treasure_spawned` removes the dead field; old saves just ignore it.

**4. `change_room` becomes two steps:** `convert_rooms(...)` mutates data synchronously and returns how many changed; a separate cosmetic `play_conversion_animation(rooms)` runs on next `show_map`. Callers set a flag only when the count is greater than zero. Alternative: keep one coroutine and await it everywhere; rejected because it blocks gameplay flow on animation and still leaves the save race.

**5. Campfire score on entry.** The reading is taken when the campfire view opens and applied on exit (or immediately, since the heal does not change it). Low-health thresholds mirror the battle ones.

**6. Score carries across acts, flags reset.** Player skill estimate is still valid in the next act; per-act flags exist to bound conversions per act.

## Risks / Trade-offs

- [Behavior changes in playtests when flags reset per act] → Expected and intended; document in tasks and compare one run per act.
- [Campfire low-HP penalty makes DDA swing too easy] → Penalties reuse the battle values and live in `DDAConfig`, easy to soften.
- [Large refactor of `run.gd`] → Keep each handler's trigger order unchanged; only move the decision body.

## Implementation notes

- The campfire conversion decision also uses the arrival HP share (not the post-rest value), so "arrived hurt" and "arrived healthy" mean what they say.
- `DDA` returns `DDAConversion`s and a small `execute()` runs them against any map-like object (`convert_rooms`), which keeps flag handling testable without scenes. `Map.change_room()` stays as a count-only wrapper for event rooms.
- Flags used to be written to the save file but never restored on Continue; they now live in `RunStats.dda_state`, so they persist. Saves made before this change simply start with the flags clear.

