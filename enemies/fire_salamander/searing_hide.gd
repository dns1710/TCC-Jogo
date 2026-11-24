class_name SearingHide
extends EnemyAction
## Passive (never chosen as an action). While the hide is up, each hit the Salamander
## takes gives the player 1 Scorch. After every third of its actions the hide is down
## until it starts its next action.

const SCORCH := preload("res://statuses/status_scorch.tres")
const CYCLE := 3

var hide_up := true
var _actions := 0


func _ready() -> void:
	type = Type.CONDITIONAL
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	_connect.call_deferred()


func _connect() -> void:
	if is_instance_valid(enemy) and not enemy.damage_received.is_connected(_on_damage_received):
		enemy.damage_received.connect(_on_damage_received)


func _process(_delta: float) -> void:
	# The hide comes back up when the Salamander starts acting again.
	if not hide_up and is_instance_valid(enemy) and enemy.acting:
		hide_up = true


func is_performable() -> bool:
	return false


func _on_damage_received(_amount: int, which_modifier: Modifier.Type) -> void:
	if not hide_up or which_modifier != Modifier.Type.DMG_TAKEN or not is_instance_valid(target):
		return
	var applied: Status = SCORCH.duplicate()
	applied.stacks = 1
	target.status_handler.add_status(applied)


func _on_enemy_action_completed(completed: Enemy) -> void:
	if completed != enemy:
		return
	_actions += 1
	if _actions % CYCLE == 0:
		hide_up = false
