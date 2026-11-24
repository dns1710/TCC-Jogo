class_name MeleeAttackAction
extends EnemyAction
## Dash, hit (one or more times), optionally apply a status. One configurable attack
## used by most Act 2 and Act 3 enemies.

@export var dice_amount := 1
@export var dice_value := 6
@export var hits := 1
## Status applied to the target after the hits, with its stacks for stacking statuses.
@export var status: Status
@export var status_stacks := 1
## Extra damage per other living enemy with the same stats tag (pack bonus).
@export var pack_tag := ""
@export var pack_bonus := 1
## Damage multiplier when the target has this status id.
@export var bonus_vs_status := ""
@export var bonus_multiplier := 1.5
## When above 0 this is a CONDITIONAL action available once the actor holds that much block.
@export var requires_block := 0
@export var clear_block_on_hit := false


func is_performable() -> bool:
	if requires_block <= 0 or not enemy:
		return false
	return enemy.stats.block >= requires_block


func roll_damage() -> int:
	var damage := Dice.roll(dice_amount, dice_value, enemy.stats.attack)
	if pack_tag != "":
		damage += pack_bonus * _other_pack_members()
	if bonus_vs_status != "" and target.status_handler._has_status(bonus_vs_status):
		damage = floori(damage * bonus_multiplier)
	return damage


func perform_action() -> void:
	if not enemy or not target:
		return
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(enemy, "global_position", end, 0.4)
	for i in hits:
		tween.tween_callback(_hit)
		if i < hits - 1:
			tween.tween_interval(0.15)
	if status:
		tween.tween_callback(_apply_status)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)
	tween.finished.connect(func():
		if is_instance_valid(enemy):
			Events.enemy_action_completed.emit(enemy)
	)


func _hit() -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(target):
		return
	var damage_effect := DamageEffect.new()
	damage_effect.amount = roll_damage()
	damage_effect.sound = sound
	damage_effect.source = enemy
	var targets: Array[Node] = [target]
	damage_effect.execute(targets)
	if clear_block_on_hit:
		enemy.stats.block = 0


func _apply_status() -> void:
	if not is_instance_valid(target):
		return
	var applied: Status = status.duplicate()
	if applied.stack_type == Status.StackType.INTENSITY:
		applied.stacks = status_stacks
	var effect := StatusEffect.new()
	effect.status = applied
	var targets: Array[Node] = [target]
	effect.execute(targets)


func _other_pack_members() -> int:
	var count := 0
	if enemy.get_parent():
		for child in enemy.get_parent().get_children():
			if child is Enemy and child != enemy and not child.is_queued_for_deletion() \
					and child.stats.health > 0 and child.stats.tag == pack_tag:
				count += 1
	return count
