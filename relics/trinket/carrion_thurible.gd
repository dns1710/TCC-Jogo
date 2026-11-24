class_name CarrionThurible
extends Relic
## When an enemy dies, its Poison, Burn and Scorch jump to one random other enemy.


var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)


func _on_enemy_died(dead: Enemy) -> void:
	if not is_instance_valid(relic_ui) or not is_instance_valid(dead):
		return
	var survivors := ItemFx.enemies(relic_ui).filter(func(e: Enemy): return e != dead)
	if survivors.is_empty():
		return
	var copied := false
	var chosen: Enemy = survivors[randi() % survivors.size()]
	var poison := ItemFx.get_status(dead, "Poison")
	var burn := ItemFx.get_status(dead, "Burn")
	var scorch := ItemFx.get_status(dead, "Scorch")
	for enemy: Enemy in [chosen]:
		if poison:
			ItemFx.apply(enemy, ItemFx.POISON)
			copied = true
		if burn:
			ItemFx.apply(enemy, ItemFx.BURN)
			copied = true
		if scorch:
			ItemFx.apply(enemy, ItemFx.SCORCH, scorch.stacks)
			copied = true
	if copied:
		ItemFx.flash(relic_ui)
