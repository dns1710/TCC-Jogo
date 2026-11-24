class_name ItemFx
extends RefCounted
## Small helpers the item scripts share: finding actors, applying statuses, reading statuses.

const SCORCH := preload("res://statuses/status_scorch.tres")
const SPEED_DOWN := preload("res://statuses/status_speed_down.tres")
const BRITTLE := preload("res://statuses/status_brittle.tres")
const SUNDER := preload("res://statuses/status_sunder.tres")
const FREEZE := preload("res://statuses/status_freeze.tres")
const WARD := preload("res://statuses/status_ward.tres")
const ATTACK_UP := preload("res://statuses/status_attack_up.tres")
const POISON := preload("res://statuses/status_poison.tres")
const BURN := preload("res://statuses/status_burn.tres")

## Debuffs whose stacks Warden's Visage amplifies.
const STACKING_DEBUFFS: Array[String] = ["Scorch", "SpeedDown", "AttackDown"]


static func player(from: Node) -> Player:
	if not is_instance_valid(from) or not from.is_inside_tree():
		return null
	var found := from.get_tree().get_first_node_in_group("player") as Player
	if found == null or found.is_queued_for_deletion() or found.stats == null or found.stats.health <= 0:
		return null
	return found


static func enemies(from: Node) -> Array[Enemy]:
	var result: Array[Enemy] = []
	if not is_instance_valid(from) or not from.is_inside_tree():
		return result
	for node in from.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion() and enemy.stats.health > 0:
			result.append(enemy)
	return result


static func is_alive(actor: Node) -> bool:
	return is_instance_valid(actor) and not actor.is_queued_for_deletion() and actor.stats != null and actor.stats.health > 0


static func is_boss(enemy: Node) -> bool:
	return enemy is Enemy and enemy.stats.freeze_immune


## Applies a fresh copy of a status resource, optionally with a stack count.
static func apply(target: Node, status: Status, stacks := 0) -> void:
	if not is_instance_valid(target):
		return
	var copy: Status = status.duplicate()
	if stacks > 0:
		copy.stacks = stacks
	var effect := StatusEffect.new()
	effect.status = copy
	effect.execute([target])


## True when the actor carries any debuff (the ones Ward would negate).
static func is_afflicted(actor: Node) -> bool:
	for id in StatusHandler.DEBUFF_IDS:
		if has_status(actor, id):
			return true
	return false


static func has_status(actor: Node, id: String) -> bool:
	var status := get_status(actor, id)
	return status != null


static func get_status(actor: Node, id: String) -> Status:
	if not is_instance_valid(actor) or actor.get("status_handler") == null:
		return null
	var status: Status = actor.status_handler._get_status(id)
	if status == null:
		return null
	if status.can_expire and status.duration <= 0:
		return null
	if status.stack_type == Status.StackType.INTENSITY and status.stacks <= 0:
		return null
	return status


## die_sides is the die the amount was rolled with (0 for flat damage); Brittle adds one more die of it.
static func hit(target: Node, amount: int, source: Node = null, die_sides := 0) -> void:
	if not is_alive(target) or amount <= 0:
		return
	var effect := DamageEffect.new()
	effect.amount = amount
	effect.source = source
	effect.die_sides = die_sides
	effect.execute([target])


static func block(target: Node, amount: int) -> void:
	if not is_instance_valid(target) or amount <= 0:
		return
	var effect := BlockEffect.new()
	effect.amount = amount
	effect.execute([target])


static func flash(relic_ui: RelicUI) -> void:
	if is_instance_valid(relic_ui) and relic_ui.is_inside_tree():
		relic_ui.flash()
