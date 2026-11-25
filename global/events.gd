extends Node

# Player-related events
signal player_hit
signal player_died
signal player_turn_ended
signal player_turn_started
signal player_atb_ready
signal player_action_completed
signal player_damaged(attacker: Enemy, damage: int)
signal player_health_changed(player: Player)
## Before the player's attack lands: its targets, so items can read their state first.
signal player_attack_started(targets: Array)
## After the player's attack resolved: its targets and the weapon damage rolled.
signal player_attacked(targets: Array, damage: int)

# Enemy-related events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_turn_started
signal enemy_died(enemy: Enemy)
signal enemy_selected(enemy: Enemy)

# Status-related events (the owner is the actor, Player or Enemy)
signal status_added(owner: Node, status: Status)
signal status_removed(owner: Node, status: Status)
signal status_absorbed(owner: Node, status: Status)

# Battle-related events
signal battle_start
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal action_used(action: Action)

# Map-related events
signal map_exited(room: Room)
signal animation_dda_lock(value: bool)
## The difficulty adjustment converted at least one room: harder is true when any
## conversion made a battle, false when it only made the game easier.
signal dda_adjusted(harder: bool)

# Shop-related events
signal shop_entered(shop: Shop)
signal shop_relic_bought(relic: Relic, gold_cost: int)
signal shop_exited

# Campfire-related events
signal campfire_exited

# Battle Reward-related events
signal battle_reward_exited

# Reward-related events
signal reward_exited

# Treasure Room-related events
signal treasure_room_exited(found_relic: Relic)

# Relic-related events
signal relic_tooltip_requested(relic: Relic)

# Random Event room-related events
signal event_room_exited

# Act transition events
signal act_transition_finished

# Tutorial events
signal tutorial_requested
signal tutorial_finished
