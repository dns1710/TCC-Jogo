class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D


func is_performable() -> bool:
	return false


func perform_action() -> void:
	pass


func update_intent_text() -> void:
	intent.current_text = intent.base_text


## Rolls an attack of `amount` dice with `sides` faces. Adds the actor's attack stat as the flat part
## and any extra dice the act gives it (bosses), using the attack's own die size.
func roll_attack(amount: int, sides: int) -> int:
	var extra := enemy.extra_attack_dice if enemy else 0
	return Dice.roll(amount + extra, sides, enemy.stats.attack)
