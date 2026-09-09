extends Node

# Player-related events
signal player_hit
signal player_died
signal player_turn_ended
signal player_turn_started
signal player_atb_ready
signal player_action_completed
signal player_damaged(attacker: Enemy, damage: int)

# Enemy-related events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_turn_started
signal enemy_died(enemy: Enemy)
signal enemy_selected(enemy: Enemy)

# Battle-related events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal action_used(action: Action)

# Map-related events
signal map_exited(room: Room)

# Shop-related events
signal shop_entered(shop: Shop)
signal shop_relic_bought(relic: Relic, gold_cost: int)
signal shop_exited

# Campfire-related events
signal campfire_exited

# Battle Reward-related events
signal battle_reward_exited

# Treasure Room-related events
signal treasure_room_exited(found_relic: Relic)

# Relic-related events
signal relic_tooltip_requested(relic: Relic)

# Random Event room-related events
signal event_room_exited
