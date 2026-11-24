# Adding an event

Events are data. No script needed for most.

1. In the editor, create a new `EventDefinition` resource in `events/<act>/` (title, body, choices).
2. Each `EventChoice` has a label, optional costs (gold, HP, rerolls, or `all_in`) and `outcomes`.
   - Several outcomes: picked by `weight`.
   - With a `check_stat`: `outcomes[0]` is success, `outcomes[1]` is failure; chance is `check_base + check_per_point * stat`.
3. Each `EventOutcome` has the story `text` and its effects: gold, `bet_multiplier` (all-in payout), hp, `heal_share`, max_hp, attack, block, speed, rerolls, dda, `relic_rarity` (0 common to 3 mythic), room conversion.
   The effect lines ("+45 gold", "-8 HP") on the outcome screen are generated for you.
4. Add the resource to the act's pool: `event_room_pool.tres` (Forest), `pools/ice_events.tres`, `pools/fire_events.tres`.
5. Run `Godot --headless --path . res://tools/verify_event_rooms.tscn`: it checks lengths, counts, every choice end to end.

Limits (256x144 screen): title 28 characters, body 120, choice label 34, outcome text 100, at most 4 choices.

Balance anchors: about 50 gold per permanent stat point (attack 70, speed 55, block 45), a relic is 90 to 120 gold, a campfire heals 30% of max HP, +5 max HP is a free gift.

For something a data event cannot do, set `custom_scene` on the definition to a scene whose script extends `EventRoom` (see `script_templates/Node/event_room_template.gd`); it receives `definition`, `character_stats`, `run_stats`, `relic_handler`, `map` and `relic_pool`, and must emit `Events.event_room_exited` when done.
