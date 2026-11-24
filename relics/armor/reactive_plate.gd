class_name ReactivePlate
extends Relic
## When a hit fully breaks your block, the attacker takes 2d4 and becomes Brittle.

@export var dice_amount := 2
@export var dice_value := 4

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.connect(_on_player_damaged)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_damaged.is_connected(_on_player_damaged):
		Events.player_damaged.disconnect(_on_player_damaged)


func _on_player_damaged(attacker: Node, damage: int) -> void:
	var player := ItemFx.player(relic_ui)
	if player == null or not attacker is Enemy or not ItemFx.is_alive(attacker):
		return
	# Player.take_damage announces the hit before the block is spent, so this is the pre-hit block.
	var block := player.stats.block
	if block <= 0 or damage < block:
		return
	ItemFx.hit(attacker, Dice.roll(dice_amount, dice_value))
	ItemFx.apply(attacker, ItemFx.BRITTLE)
	ItemFx.flash(relic_ui)
