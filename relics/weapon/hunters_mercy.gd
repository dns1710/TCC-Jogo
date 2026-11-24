class_name HuntersMercy
extends Relic
## Executes enemies left under 30% health by your hit. Bosses cannot be executed: a hit on a boss
## already under 30% deals 50% more instead. A kill raises your turn bar to at least 50%.

@export var execute_share := 0.3
@export var boss_bonus := 0.5
@export var kill_bar := 0.5
## Window after an attack in which an enemy death counts as that attack's kill.
const KILL_WINDOW_MS := 1200

var relic_ui: RelicUI
var _last_attack_ms := -100000


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	_last_attack_ms = -100000
	if not Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.connect(_on_player_attacked)
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.disconnect(_on_player_attacked)
	if Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.disconnect(_on_enemy_died)


## The hit's damage resolves a frame later, so execution is judged after it landed.
func on_attack_hit(targets: Array[Node]) -> void:
	if not is_instance_valid(relic_ui) or not relic_ui.is_inside_tree():
		return
	var tree := relic_ui.get_tree()
	for i in 3:
		await tree.process_frame
	for target in targets:
		if not ItemFx.is_alive(target) or ItemFx.is_boss(target):
			continue
		if target.stats.health <= target.stats.max_health * execute_share:
			target.take_damage(target.stats.health + target.stats.block, Modifier.Type.NO_MODIFIER)
			ItemFx.flash(relic_ui)


func _on_player_attacked(targets: Array, damage: int) -> void:
	_last_attack_ms = Time.get_ticks_msec()
	for target in targets:
		if ItemFx.is_alive(target) and ItemFx.is_boss(target) \
				and target.stats.health <= target.stats.max_health * execute_share:
			ItemFx.hit(target, int(damage * boss_bonus))
			ItemFx.flash(relic_ui)


func _on_enemy_died(_enemy: Enemy) -> void:
	if Time.get_ticks_msec() - _last_attack_ms > KILL_WINDOW_MS:
		return
	var player := ItemFx.player(relic_ui)
	if player:
		player.boost_atb(kill_bar)
		ItemFx.flash(relic_ui)
