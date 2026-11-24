# Design

## Context

`EnemyHandler.setup_enemies` instantiates a battle scene once and duplicates its `Enemy` children; `ATBManager` iterates `enemy_handler.get_children()` every frame, so a node added later is picked up automatically, but its starting bar is only set in `start_battle`. A battle ends when `EnemyHandler` has no children (`Battle._on_enemies_child_order_changed`). Enemy actions are `EnemyAction` nodes: conditional actions fire first, otherwise a weighted pick, and each action ends by emitting `Events.enemy_action_completed`. The Bomb (prepare, then explode) and Bear boss (wake, then enrage at a threshold) hand-roll the patterns this change generalizes. Existing battle scenes place enemies between roughly x 148 to 211 and y 47 to 100 on a 256x144 screen. `Battle` draws a fixed forest `Background` sprite. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- A safe, tested way to add and remove enemies mid-fight, and the common action patterns as reusable pieces.

**Non-Goals:**
- Specific enemies or bosses; rewriting the existing Bomb and Bear actions (they keep working as they are).

## Decisions

**1. `EnemyHandler.spawn_enemy(stats, summoner)`.** Instantiates `enemy.tscn`, assigns `stats`, picks the first free of 5 fixed slots (derived from existing layouts), plays a short scale-in tween, sets the turn bar to 0, connects the same status signal as setup, and records `summoner` on the new enemy. Returns null when full. Alternative: pre-place hidden enemies in the battle scene and "reveal" them; rejected, it limits summons to scene design and breaks respawning.

**2. Fizzle in `EnemyHandler`.** It already listens to `Events.enemy_died`; when the dead enemy has living minions it marks each for fizzle. A fizzling minion dies on its next `enemy_action_completed`, with a 6 second fallback timer. Minions keep `summoner` as a weak link (checked with `is_instance_valid`).

**3. Reusable actions as base scripts.** `HealAlliesAction` (amount), `SummonAction` (stats, max alive, cooldown in actions), `TelegraphAction` + `TelegraphedStrikeAction` (prepare sets `special_state`, strike requires it, generalizing the Bomb), and `ThresholdAction` (HP share, once). They extend `EnemyAction` so AI scenes use them like any action.

**4. Battle background by act.** `Act` gains `battle_background: Texture2D`; `Run` passes it to `Battle` before `start_battle`; `Battle` swaps the sprite texture and rescales it to fill 256x144 (the source art is 1748x900, so scale about 0.1465 by 0.16). The default forest remains when null.

**5. Cap of 5.** Matches the available slots and keeps the screen readable at 256x144.

## Risks / Trade-offs

- [New enemies miss ATB setup] → `spawn_enemy` initializes the bar itself; covered by a test that waits for a spawned enemy to act.
- [Battle ends early while a spawn is pending] → Spawning happens inside an action before `enemy_action_completed`, so the summoner is still alive and counted.
- [Fizzle edge cases (summoner and minion die together)] → Tests cover minion-first, summoner-first and simultaneous deaths.
- [Backgrounds too large or too bright] → Reuse the forest sprite's dim modulate and check a rendered screenshot.
