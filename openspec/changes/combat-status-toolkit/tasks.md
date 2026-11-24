# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`. Run checks after a headless import (`--import --quit`).

## 1. Test harness first

- [x] 1.1 Add `tools/verify_combat_statuses.tscn` and script covering every scenario in the `combat-statuses` spec on both an enemy and the player (combined slows, Freeze timing and immunity, Brittle consume, Scorch decay, Ashen halving and expiry, Sunder ignoring block once, tooltips non-empty). Verify: it exits 1 on the current code and names the missing statuses.

## 2. Rate modifiers

- [x] 2.1 Add the shared `ATBModifiers` helper; make `atb_rate_multiplier` the product of sources on `Player` and `Enemy`; switch `SpeedDownStatus` to source `"speed_down"`. Verify: `verify_combat_pacing` passes unchanged and a new test shows Speed Down and a second source combine and end independently.

## 3. Statuses

- [x] 3.1 Add `Freeze` (1.5s stop, 4s immunity, boss immunity flag) with its status resource and tooltip. Verify: the harness shows the bar frozen then resuming, no refreeze during immunity, and an immune boss unaffected.
- [x] 3.2 Add `damage_received` on both actors and the `Brittle` status (+50%, consumed by the next hit, no stacking). Verify: the harness shows 8 damage becomes 12 once, then 8.
- [x] 3.3 Add `Scorch` (stacking, damage equals stacks then loses one). Verify: the harness shows 3, 2, 1 damage then removal, and stacking 2 onto 1 gives 3.
- [x] 3.4 Add `block_gain_multiplier` to the actors, read it in `BlockEffect`, and add `Ashen` (halved for 3 actions). Verify: the harness shows 9 block becomes 4 and returns to normal after 3 actions.
- [x] 3.5 Add the one-shot ignore-block flag in `take_damage` and the `Sunder` status. Verify: a target with 10 block and Sunder takes 6 to health and keeps its block, then the next hit is blocked normally.

## 4. Placeholder icons

- [ ] 4.1 Generate recolored placeholder icons for the five statuses into `art/arte nao tao verdadeira/` with a one-off script and assign them to the status resources. Verify: all five statuses show an icon in a rendered battle screenshot.

## 5. Integration

- [x] 5.1 Boot check and all suites (`verify_combat_statuses`, `verify_combat_pacing`, `verify_act_flow`, `verify_event_rooms`, `verify_dda`, `verify_item_pools`, `verify_map_generation`). Verify: no script errors and every suite exits 0.

## Workflow follow-up

- Archive the change after review so `combat-statuses` becomes a main spec.
