# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`.

## 1. Turn bar

- [x] 1.1 Create one shared `ATB_MAX = 20` used by `player.gd`, `enemy.gd` and the bars' `max_value`; scale starting progress in `atb_manager.gd`. Verify: boot check shows no script errors, and a headless scene steps a speed-4 actor and asserts it acts at 5.0 seconds.

## 2. Speed Down

- [x] 2.1 Add `atb_rate_multiplier` to actors and rewrite `SpeedDownStatus` to set it to `0.85 ^ stacks` instead of changing `stats.speed`. Verify: a headless scene asserts a speed-4 actor with 3 stacks has rate 2.45 and a speed-3 actor with 2 stacks acts at about 9.2 seconds, and `stats.speed` is unchanged.
- [x] 2.2 Decay one stack when the owner completes an action and remove the status at zero (enemy and player paths). Verify: the headless scene asserts 3, 2, 1 then removed across three actions.
- [x] 2.3 Update the status tooltip to show percent slower and stacks left. Verify: manual check of the tooltip on a 2-stack status reads about 28% slower and 2 stacks.

## 3. Relic waits

- [x] 3.1 Replace the fixed relic interval with `min(0.25, 1.5 / count)`. Verify: a headless scene activating 10 relics finishes within 1.5 seconds.

## 4. Integration

- [x] 4.1 Playtest an Act 1 battle with Icy and with Croc grab at the new pace; note whether 20 feels too fast. Verify: boot check clean, and the note recorded in `design.md`'s trade-offs if the value changes.
