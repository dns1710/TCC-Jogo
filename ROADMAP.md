# Roadmap after `item-slop`

Written on the `item-slop` branch so it travels to `main` with the merge. When a branch starts one of these,
run the OpenSpec propose workflow from the matching section and delete or tick the section when it is archived.

Context: a Godot 4.6 roguelike deck-builder reskinned as a dice RPG (TCC project). ATB combat with two actions
(Attack = weapon dice + ATTACK, Block = +5), three acts (forest, ice, fire) with bosses, 63 relics after
`item-pool-expansion`, a difficulty system (DDA) scoring the player, 24 events, a tutorial. Web export served by
Caddy in Docker (`build/`). Headless checks: `tools/verify_*.tscn`.

## Standing design rules (decided in playtests)
- **Dice, not flat numbers or percentages.** Item effects that deal damage, grant block or heal state dice
  (Brittle = one extra die of the hit's size; Maul +1d4 per 5 block; Gloves +1d4). Gear stat bonuses
  (+BLOCK/+ATTACK/+SPEED) and status stack counts stay numbers.
- A status applied by the hit itself never counts as "already afflicted".
- Enemy scaling lives in the act resources (`enemy_health_scale`, `enemy_attack_bonus`, `boss_extra_dice`). Brittle
  scales with enemy dice on its own.

## Order
1. Rebalancing (DONE, archived 2026-11-24)
2. Art overhaul (done by hand by the owner; see notes)
3. Items screen (codex)
4. Scoring overhaul + Supabase
5. Scoutmaster dialogue (already specified)

## 1. Rebalancing (DONE, archived 2026-11-24)
All four changes are implemented, archived under `openspec/changes/archive/`, and their specs live in `openspec/specs/`.

- `item-balance-report` - `tools/report_item_balance.tscn`. Budgets use a weighted stat total (SPEED 1.0, ATTACK 0.7,
  BLOCK 0.3), taken from what a point is worth in the simulator. No relic is over budget; the exception list is empty.
- `reward-drop-rates` - `custom_resources/reward_config.tres`: 35% drop on regular battles with pity after 2 misses,
  tier 2 always drops, bosses (acts 1 and 2) offer a choice of 3 relics of different rarities, shops sell 2 relics at
  x1.25. `dda_config.tres` `shop_all_bought_items` is 2 to match the shop. `tools/simulate_rewards.tscn` shows relics
  held at the end of a run fall from 33.6 to about 24.
- `enemy-scaling` - acts: x1.0 / x1.25 / x1.5 health, +0 / +1 / +2 attack, boss dice +0 / +0 / +1 (Krampus with a
  die would out-hit the player's 40 health). Bosses are flagged with `EnemyStats.is_boss`.
- `item-balance-pass` - `tools/simulate_balance.tscn` (ranking, builds, loadout comparison). Glass Heart +3 ATK / +2 SPD,
  Heavier Armor +10 BLOCK / -1 SPD, Heavy Plate and Heavy Helmet +4 BLOCK. Needle and Barbarian Armor data fixed.

**Open, owner decided to keep as is:** the simulator puts typical builds at 28% HP lost per act-1 fight (on target)
but 84% in act 2 and 100% in act 3 (targets 25-40% and 30-45%). Without act scaling it is still 51% and 77%, so the gap is
mostly base act 2-3 enemies (golems, wolf packs). The simulator ignores statuses and smart play, so it is probably
harsher than real play. Decide after playtests; relic tuning cannot close it.

## 2. Art overhaul (owner, manual)
- Keep sizes (items 16x16, statuses 10x10) and file names so item resources keep their icons.
- `tools/verify_item_art.gd` fails on pixels outside `art/src/palette.txt`. Scope that check to icons built from
  `art/src/*.pix`, or make it a warning, then re-run it.
- `art/src/*.pix` and `tools/build_icons.gd` become stale once the PNGs are replaced: delete them or mark them as
  not the source of truth.
- Then close task 8.4 of `item-pool-expansion` (one run per act, note icons that read poorly) and archive it.

## 3. Items screen (codex)
- Main menu gets an "Items" button (menu today: Continue, New Run, Tutorial, Exit). Viewport is 256x144, so use a
  grid of 16x16 icons with slot and rarity filters, and the existing hover tooltip.
- Data source: scan `relics/` (not a hand-written list). Show everything, no unlocks.
- Second tab: statuses with icon and plain description, because item text names statuses in capitals.
- Spec: `item-codex`. Build after the art lands.

## 4. Scoring overhaul + Supabase
- `main` has no scoring or Supabase code. The old version lives only on `origin/BranchAPI`
  (`global/score.gd`, `global/supabase_service.gd`): 10 per room + gold + 100 for a win, submitted only on death,
  keyed by a "Player - datetime" name, anon key embedded in the client, PATCH by name to update.
- Needs the Supabase plugin/connector enabled so Claude can inspect and change the real tables and policies.
- Specs: `run-scoring` (rooms cleared, HP left, gold, DDA difficulty multiplier; win and loss), `score-submission`
  (submit on win and loss, offline handling, name entry), `leaderboard-backend` (schema, RLS insert-only,
  server-side validation through a Postgres function or Edge Function).
- `add-run-scoring` is mentioned in `scoutmaster-narrative` but does not exist in the repo.

## 5. Scoutmaster dialogue
- Change `scoutmaster-narrative` exists with approved copy (opening scene, difficulty remarks, win-screen epilogue,
  rename the project to "Rogue Playing Game"). 1 of 9 tasks done.
- Both it and scoring edit the win screen: do it after scoring, keep edits additive.

## Loose ends
- `hotfix-reroll-button-campfire-act1`: 2 tasks left.
- `smore.gd` looks up status id `"attackup"` but the real id is `"AttackUp"`, so its Attack Up never clears.
- Reactive Plate cannot tell when Sunder let a hit skip block, so it may misjudge a block break in that case.
