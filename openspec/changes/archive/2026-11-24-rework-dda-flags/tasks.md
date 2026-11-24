# Tasks

`$GODOT` = `D:\Documents\Godot\Godot_v4.6.2-stable_win64.exe`.

## 1. DDA component and state

- [x] 1.1 Add `DDAConfig` (current thresholds as defaults) and `DDAState` (the saved flags, `reset_for_act()`), attach state to the run stats, remove `dda_treasure_spawned`. Verify: boot check shows no script errors and old saves still load.
- [x] 1.2 Add one score-change function with a reason and route battle, campfire, relic pickup (`relic_handler.gd`) and the two events through it. Verify: a headless unit scene applies each source and asserts the score stays in 0..100 and each change is recorded.

## 2. Decisions and flags

- [x] 2.1 Move every conversion decision out of `run.gd` into DDA methods returning conversion lists; keep trigger order and thresholds. Verify: a headless scene feeds fixed scores/HP/gold and asserts the same conversions as the old inline code (table of at least 8 cases from the current thresholds).
- [x] 2.2 Set a once-per-act flag only when the conversion count is greater than zero. Verify: the headless scene shows a no-candidate trigger leaves the flag available.
- [x] 2.3 Take the campfire score on entry with low-HP penalties. Verify: entering at 30% health lowers the score even after resting.

## 3. Map application and saves

- [x] 3.1 Split `change_room` into synchronous data conversion (returns count) and a cosmetic animation played on map show; fix `_on_shop_exited` ordering so conversions precede the save. Verify: convert, save immediately, load: the saved map has the converted room.
- [x] 3.2 Save and restore `DDAState`; call `reset_for_act()` from the act transition (needs `add-act-framework`, otherwise from run start). Verify: save with a flag used, continue, flag still used; new act resets flags and keeps the score.

## 4. Integration

- [x] 4.1 Boot check plus one full playthrough noting every conversion that fires. Verify: no script errors, and conversions match the table from 2.1.
