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
- Enemy scaling does not exist yet. Brittle scales with enemy dice on its own.

## Order
1. Rebalancing (start here)
2. Art overhaul (done by hand by the owner; see notes)
3. Items screen (codex)
4. Scoring overhaul + Supabase
5. Scoutmaster dialogue (already specified)

## 1. Rebalancing
Split into three changes, in this order:

0. `item-balance-report` - a headless script that prints every relic in one table (name, slot, rarity, stat
   total, weapon dice and average damage, effect text, statuses touched), grouped by rarity, flagging anything above
   its rarity budget (about 1 point common, 2 uncommon, 3 rare, build-defining mythic). Builds the data for 1c.
1. `reward-drop-rates` - today every battle drops 1 relic (100%), the first battle guarantees a weapon plus a
   common, shops sell 3 relics and chests/events add more, so the player picks their build every run.
   Suggested: about 45% on regular battles with a pity counter, 100% on tier 2, a choice of rarity on bosses, gold as
   the consolation reward, fewer or pricier shop relics. The DDA score gains points per relic picked up
   (+1/+3/+5/+8 by rarity), so fewer relics lowers the score: retune `dda_config.tres` in the same change.
   Specs: `reward-drop-rates`, plus a modified requirement for how DDA counts relics.
2. `enemy-scaling` - enemies have fixed stats per type. Add `enemy_health_scale` and `enemy_attack_bonus` to the
   `acts/*.tres` resources and use extra dice on bosses. Specs: `enemy-scaling`, `act-difficulty-curve`.
3. `item-balance-pass` - tune numbers from the report. Known candidates: Cracked Visor, Frostfire Pike, Glass
   Heart, Phoenix Feather. Do after 1 so the number of items a player holds is known. Consider a small headless
   simulator so numbers come from data.

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
- `tools/run_suite.ps1` points at a Godot path that does not exist on the dev machine
  (`C:\Users\usuario\Documents\Setups\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` works).
- `openspec/specs/` is empty until the first change is archived.
- Reactive Plate cannot tell when Sunder let a hit skip block, so it may misjudge a block break in that case.
