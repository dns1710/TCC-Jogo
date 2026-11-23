class_name GreatAxe
extends Relic

@export var dice_amount := 1
@export var dice_value := 4

var first_time := true
var relic_ui: RelicUI

func activate_relic(_owner: RelicUI) -> void:
	relic_ui = _owner
	first_time = true
	
	if not Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.connect(_on_player_damaged)
	
	if Events.player_health_changed.is_connected(_grant_block):
		Events.player_health_changed.disconnect(_grant_block)
		
		
func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.disconnect(_on_player_damaged)
	if Events.player_health_changed.is_connected(_grant_block):
		Events.player_health_changed.disconnect(_grant_block)
		
		
func _on_player_damaged(_attacker: Node, _damage: int) -> void:
	if !first_time or not is_instance_valid(relic_ui):
		return
	first_time = false
	Events.player_health_changed.connect(_grant_block, CONNECT_ONE_SHOT)


func _grant_block(player: Player) -> void:
	if not is_instance_valid(player) or player.stats.health <= 0:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = Dice.roll(dice_amount, dice_value)
	block_effect.execute([player])

	if is_instance_valid(relic_ui):
		relic_ui.flash()
