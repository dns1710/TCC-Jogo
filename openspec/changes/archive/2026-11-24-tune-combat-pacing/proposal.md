# Proposal

## Why

Playtesters find combat sluggish and enemy speed debuffs far too heavy and boring. Each actor needs `30 / speed` seconds per action (3 to 7 speed for enemies, 10 seconds at the player's starting speed 3). Speed-down is a flat −1 per stack that never expires, so on a speed-3 enemy two stacks mean one action every 30 seconds: the enemy effectively stops acting and the fight becomes an HP grind.

## What Changes

- Lower the ATB fill requirement from 30 to 20 for the player and all enemies, held in one shared constant (so it can be retuned quickly, for example once the planned parry mechanic exists). Starting ATB stays proportional.
- Make Speed Down percentage-based: each stack multiplies the actor's ATB fill rate by 0.85 (so 3 stacks is about 61%, 5 stacks about 44%), with no cap on stacks and never a full stop.
- Make Speed Down expire: after each of the affected actor's actions it loses one stack.
- Show the current slow and stacks left in the status tooltip.
- Cap total relic-activation waiting at each combat phase to 1.5 seconds regardless of relic count (0.25 seconds per relic, compressed above 6 relics).

Out of scope: new ways for the player to buff themselves (separate content task), the parry mechanic, the starter armor's −2 speed (revisit after playtesting at the new pace), DDA conversion animation timing (see `rework-dda-flags`).

## Capabilities

### New Capabilities
- `combat-pacing`: how fast actors fill their turn bar, how Speed Down slows them and for how long, and how long relic activation may delay combat.

### Modified Capabilities

None.

## Impact

- Code: `scenes/player/player.gd`, `scenes/enemy/enemy.gd` (shared `ATB_MAX`, rate modifier), `scenes/battle/atb_manager.gd` (starting ATB), `statuses/status_speed_down.gd/.tres`, `scenes/relic_handler/relic_handler.gd` (`RELIC_APPLY_INTERVAL`), tooltip text.
- Affected content: Icy relic (applies Speed Down on hit) and Croc grab (applies it to the player) get the new behavior automatically.
- No dependency on the other changes.
