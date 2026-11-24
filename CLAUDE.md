# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Godot 4.6 (GDScript, Mobile renderer) roguelike RPG built for a TCC (undergraduate thesis). It started from the "Deck Builder Tutorial" project (the project name and export file names still use that) but the card system has been replaced. It is now a real-time **ATB** (active time battle) combat game with dice-rolled damage, gear slots, and **Dynamic Difficulty Adjustment (DDA)** that rewrites the map based on player performance. Code comments and some identifiers are in Portuguese.

## Project rules

- Game name: **RoguePlayingGame**, a roguelike inspired by Slay the Spire, focused on ATB and DDA.
- Repository: https://github.com/dns1710/TCC-Jogo (version control on GitHub; commit gradually, in small steps).
- Make all changes in `D:\Documents\RolePlayingGame\TCC-Jogo`. Full file access is granted there.
- Final delivery deadline: **2026-11-24**.
- Don't generate new sprites or sounds unless asked, to save tokens and context.
  - If a free library has good sounds, point to it and say which file to use when needed, but never download or use one without permission.

## Running / building

- There is no build system, linter, or test suite. Open `project.godot` in the Godot 4.6 editor and run (F5). The main scene is the main menu (`scenes/ui/main_menu.tscn`). Godot is not on PATH on this machine.
- `test_data/test_run_stats.tres` is hand-made test data, not automated tests.
- Web export: the `Web` preset in `export_presets.cfg`. `build/` serves `build/web-export/` with Caddy (`docker compose up` inside `build/`, port 3000). The Caddyfile sets the COOP/COEP headers Godot's web build needs.
- Saves go to `user://savegame.tres` (`SaveGame`). Delete it when save-format changes break loading.
- Ignore the `*.tscn<digits>.tmp` files. They are editor leftovers. Do not hand-edit `.uid` files.
- `openspec/` is set up for spec-driven change proposals (OpenSpec, `schema: spec-driven`), but it has no specs yet.

## Architecture

**Autoloads** (`project.godot`): `Events` (global signal bus, `global/events.gd`), `RNG` (seeded `RandomNumberGenerator`; seed and state are saved so runs can be resumed deterministically), `Shaker`, `MusicPlayer`, `SFXPlayer`. Systems talk to each other mostly through `Events` signals, not direct references. Some lookups use groups (`player`, `enemies`, `relic_handler`).

**Run flow** — `scenes/run/run.gd` (`Run`) is the orchestrator. It owns `RunStats` (gold, rerolls, `dda_score`), the player's `CharacterStats`, the `Map`, and the `RelicHandler`. Each room's scene is swapped into the `CurrentView` node by `_change_view()`. Room exits come back as `Events.*_exited` signals and return to the map. The run is saved on every map transition (`_save_run`).

**Map** — `scenes/map/map_generator.gd` builds 2 regions × 13 floors, 3 columns wide. Each `Room` resource has a `type`, a `BattleStats` (taken from `battles/battle_stats_pool.tres` by tier 0–3), or an `event_scene` (from `scenes/event_rooms/event_room_pool.tres`). `map.change_room(from_type, to_type)` swaps the types of reachable rooms. DDA uses this, and so does the player's reroll mechanic.

**DDA** — `custom_resources/dda.gd` changes `RunStats.dda_score` (0–100, starts at 50) based on HP after battles and campfires. `RelicHandler.add_relic` also raises it by item rarity. The DDA decisions live in `run.gd`. `_on_battle_won`, `_on_campfire_exited`, `_on_shop_exited`, and `_show_map` (after a treasure) look at the score, HP%, gold, and item count, then call `map.change_room`. The flags `dda_shop_changed`, `dda_treasure_spawned`, and `dda_treasure_pending` limit how often this happens, and they are saved in `SaveGame`. `_prepare_battle` raises tier-1 fights to tier 2 when the score is ≥ 75.

**Combat** — `scenes/battle/battle.gd` sets up `PlayerHandler`, `EnemyHandler`, and `ATBManager`. `ATBManager._process` fills ATB gauges, which scale with speed. When the player is ready, everything pauses until `Events.player_action_completed` fires. Ready enemies wait in a queue and act one at a time, each signalling `Events.enemy_action_completed`. The player has two `Action` resources (`custom_resources/actions/`: attack and block), triggered from `BattleUI`. Attack damage is `RelicHandler.get_weapon_damage()`: `Dice.roll(weapon_dice_amount, weapon_dice_attack, attack)`, or 1d4+attack with no weapon. Damage goes through `ModifierHandler` (DMG_DEALT/DMG_TAKEN) and `StatusHandler`.

**Enemies** — each enemy folder in `enemies/` holds an `EnemyStats` `.tres` and an `*_ai.tscn`. The AI scene is an `EnemyActionPicker` with `EnemyAction` child nodes (`*_action.gd`). The picker first takes a `CONDITIONAL` action whose `is_performable()` is true; if none, it picks a `CHANCE_BASED` one by `chance_weight`. An encounter is a `battles/mapN/tierX/*.tscn` scene of enemies plus a `BattleStats` `.tres`. That `.tres` must be added to `battles/battle_stats_pool.tres` to appear on the map.

**Relics = equipment** — `Relic` (`custom_resources/relic.gd`) has `equip` (WEAPON / HELMET / ARMOR / TRINKET), `rarity` (COMMON→MYTHIC), flat stat bonuses (`bonus_atk/blk/spd`), weapon dice, and a trigger `type`. `RelicHandler` keeps an `inventory` plus equipped slots: weapon, helmet, armor, and 2 trinkets. Only equipped relics get a `RelicUI` node and have their stats added to `max_*`. `activate_relics_by_type` runs their hooks (`activate_relic`, `get_weapon_bonus_damage`, `on_attack_hit`). When saving, `_save_run` subtracts equipped bonuses from the saved stats, and loading re-equips items by `id`. Any new stat-bearing field has to follow this subtract-then-reapply pattern. Reward and shop pools come from `Run.battle_relic_pool` (exported on `run.tscn`), so a new relic must be added there. Relic `id`s must be unique.

**Statuses** — `Status` resources in `statuses/` (`status_*.gd` + `.tres`) have a type (START_OF_TURN / END_OF_TURN / EVENT_BASED) and a stack type. The player's start and end of turn are tied to ATB ready and action completed (see `PlayerHandler`).

**Templates** — `script_templates/Node/` has editor templates for new relics, statuses, effects, enemy actions, and event rooms. Use them when adding content.

Folders named `old/` or `1old/` (`battles/old`, `enemies/old`, `relics/1old`, `statuses/old`) hold legacy tutorial content that is no longer used. Don't use them as reference for current mechanics.
