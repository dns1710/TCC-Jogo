class_name PhoenixFeather
extends Relic
## Once per combat a lethal hit is cancelled: you return to 30% of your maximum health and
## every enemy gains 3 Scorch.

@export var revive_share := 0.3
@export var scorch_stacks := 3

var used := false
var relic_ui: RelicUI


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	used = false
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if player:
		player.before_death = _on_lethal_hit


func deactivate_relic(_owner: RelicUI) -> void:
	if not is_instance_valid(relic_ui) or not relic_ui.is_inside_tree():
		return
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if player and player.before_death == _on_lethal_hit:
		player.before_death = Callable()


## Returns true to veto the death.
func _on_lethal_hit() -> bool:
	if used or not is_instance_valid(relic_ui) or not relic_ui.is_inside_tree():
		return false
	var player := relic_ui.get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return false
	used = true
	player.stats.health = maxi(1, int(player.stats.max_health * revive_share))
	Events.player_health_changed.emit(player)
	for enemy in ItemFx.enemies(relic_ui):
		ItemFx.apply(enemy, ItemFx.SCORCH, scorch_stacks)
	ItemFx.flash(relic_ui)
	return true
