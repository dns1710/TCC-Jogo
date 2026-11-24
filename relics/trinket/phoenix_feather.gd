class_name PhoenixFeather
extends Relic
## A lethal hit is cancelled once: you return to 30% of your maximum health and every enemy gains
## 1 Scorch. The feather then fizzles out and is removed from your inventory (it can drop again).

@export var revive_share := 0.3
@export var scorch_stacks := 1

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
	player._spawn_popup("FIZZLE", Color.GRAY)
	var handler := relic_ui.get_tree().get_first_node_in_group("relic_handler") as RelicHandler
	if handler:
		handler.consume_relic.call_deferred(self)
	return true
