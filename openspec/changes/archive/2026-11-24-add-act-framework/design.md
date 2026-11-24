# Design

## Context

Pools are reached in exactly five places: `MapGenerator` (exports set in `map.tscn`), four lookups in `map.gd` (reroll and `room_change_animation`) and one in `run.gd` (tier-2 upgrade). `floors_climbed` already resets per generated map, and the win check `floors_climbed == FLOORS` already means "boss of this map beaten". `SaveGame` stores no act. `run.gd` treats `row == 0` as the first-battle reward. Existing folders (`battles/map1/tier0..3`) already assume per-map pools. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- One `Act` resource as the single source of per-act content; one place that knows the current act.
- Acts 2 and 3 work end to end with placeholder content, so content can be dropped in later without code changes.

**Non-Goals:**
- Act 2/3 content, art, lore text, shop balancing.
- Changing map layout or room-type odds.

## Decisions

**1. `Act` resource + ordered list on the run.** `Act` holds name, battle pool, event pool, background and transition text. The run owns `acts: Array[Act]` (three entries) and an `act_index`. Alternative: a different map scene per act; rejected because the map logic is identical and only data differs.

**2. `generate_map(act)` and act-aware pool accessors.** The generator stops using scene-assigned pool exports; it receives the act's pools. `Map` exposes `get_battle_pool()` / `get_event_pool()` for the current act, and the four `map.gd` lookups plus `run.gd`'s tier-2 upgrade use them. This keeps the five access points on one seam.

**3. Transition as a scene.** A new `act_transition` view shows the act name and lore text, then continues; the full heal and next-map generation happen when it is dismissed. Alternative: reuse the win screen; rejected since it ends the run. It also becomes the place for future narrative.

**4. Reward condition becomes `act_index == 0 and row == 0`.** Smallest change that keeps the starting-item rule.

**5. `SaveGame.act_index` defaults to 0.** Old `savegame.tres` files simply lack the field, so Godot loads the default.

**6. Rerolls carry over unchanged.** The request named gold and relics only; leaving rerolls as-is is the lowest-surprise default.

## Risks / Trade-offs

- [Placeholder Act 2/3 pools make playtests look identical] → Act names and backgrounds differ in resources so testers can see which act they are in.
- [A save made between boss victory and transition dismissal] → Save after the transition completes; on load before that point the player replays the boss reward flow as today.
- [Pool accessors miss a call site] → Task includes grepping for direct pool exports and the harness generates maps for all three acts.
