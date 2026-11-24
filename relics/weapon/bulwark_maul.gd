class_name BulwarkMaul
extends Relic
## Deals bonus damage equal to half your current block (at most 10). The block is not spent.

@export var max_bonus := 10

var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner


func get_weapon_bonus_damage() -> int:
	var player := ItemFx.player(relic_ui)
	if player == null:
		return 0
	return mini(player.stats.block / 2, max_bonus)
