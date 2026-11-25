# Proposal

## Why

Several planned enemies and both new bosses summon allies: the Fire Campfire spawns Fire Spirits that it heals, the Fire Dragon calls imps, Krampus calls wolves. The engine cannot do this: enemies exist only as nodes placed in a battle scene, there is no way to add one mid-fight, no link between a summoner and its summons, and no shared building blocks for healing allies or telegraphed attacks (the Bomb and Bear boss each hand-roll theirs). Battles also always use the forest background, although the Ice and Fire backgrounds already exist.

## What Changes

- Let an enemy action spawn another enemy mid-battle into a free slot (5 fixed slots, at most 5 enemies alive), with a short spawn animation.
- Link summons to their summoner: when the summoner dies, its minions fizzle, dying after their next action (or after 6 seconds if they cannot act).
- Battle ends when every enemy, minions included, is gone.
- Add reusable enemy action building blocks: heal allies, summon, telegraph then heavy hit, and a one-time action at an HP threshold.
- Let each act define a battle background; battles use their act's background (forest stays the default).

Out of scope: any specific summoning enemy or boss, new statuses, final art.

## Capabilities

### New Capabilities
- `enemy-summoning`: spawning enemies mid-battle, how summons are linked to and end with their summoner, and the shared action patterns enemies build on.

### Modified Capabilities
- `act-progression`: each act can define the background its battles use.

## Impact

- Code: `scenes/enemy/enemy_handler.gd` (spawn, slots, fizzle), `scenes/enemy/enemy.gd` (owner link), `scenes/battle/battle.gd` and `battle.tscn` (background), `scenes/run/run.gd` (pass the act background), `custom_resources/act.gd` and the three act resources, new action base scripts under `scenes/enemy/`.
- Tests: new `tools/verify_enemy_summoning.tscn`.
- Needed by: `act2-ice-enemies`, `act2-boss-krampus`, `act3-fire-enemies`, `act3-boss-fire-dragon`. Independent of `combat-status-toolkit`.
- Art: none required (backgrounds `bg_neve_ato2.png` and `bg_fogo_ato3.png` already exist); see `art/ART_REQUESTS.md` for cropping notes.
