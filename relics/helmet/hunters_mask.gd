class_name HuntersMask
extends Relic

@export var dice_amount := 2
@export var dice_value := 4

var relic_ui: RelicUI

func activate_relic(_owner: RelicUI) -> void:
	relic_ui = _owner
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)

func deactivate_relic(_owner: RelicUI) -> void:
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)

func _on_enemy_died(_enemy: Enemy) -> void:
	if not is_instance_valid(relic_ui):
		return
	
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if not player or player.stats.health <= 0:
		return
		
	player.heal(Dice.roll(dice_amount, dice_value))
	relic_ui.flash()
