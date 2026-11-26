class_name TowerShield
extends Relic
## Deals 1d4 extra damage for every 5 of your current block, up to 3d4. The block is not spent.

@export var block_per_die := 5
@export var die_sides := 4
@export var max_dice := 3

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner


func get_weapon_bonus_damage() -> int:
	var player := ItemFx.player(relic_ui)
	if player == null:
		return 0
	var dice := mini(player.stats.block / block_per_die, max_dice)
	if dice <= 0:
		return 0
	return Dice.roll(dice, die_sides)
