class_name BrassKnuckle
extends Relic
## Your attacks deal an extra 1d4 to enemies that already carried a debuff before the hit.
## A debuff the hit itself applies (Poison Dagger, Snowballs...) does not count.

@export var bonus_die := 4

var relic_ui: RelicUI
var _afflicted: Array[Node] = []


func activate_relic(owner: RelicUI) -> void:
	relic_ui = owner
	_afflicted.clear()
	if not Events.player_attack_started.is_connected(_on_attack_started):
		Events.player_attack_started.connect(_on_attack_started)
	if not Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.connect(_on_player_attacked)


func deactivate_relic(_owner: RelicUI) -> void:
	if Events.player_attack_started.is_connected(_on_attack_started):
		Events.player_attack_started.disconnect(_on_attack_started)
	if Events.player_attacked.is_connected(_on_player_attacked):
		Events.player_attacked.disconnect(_on_player_attacked)


func _on_attack_started(targets: Array) -> void:
	_afflicted.clear()
	for target in targets:
		if ItemFx.is_alive(target) and ItemFx.is_afflicted(target):
			_afflicted.append(target)


func _on_player_attacked(targets: Array, _damage: int) -> void:
	for target in targets:
		if _afflicted.has(target):
			ItemFx.hit(target, Dice.roll(1, bonus_die), null, bonus_die)
			ItemFx.flash(relic_ui)
	_afflicted.clear()
