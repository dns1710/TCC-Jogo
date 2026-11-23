class_name StatusBurn
extends Status

@export var dice_amount := 1
@export var dice_damage := 6
@export var cure_turn := 3

var current_turn := 0

func apply_status(target: Node) -> void:
	current_turn += 1
		
	if is_instance_valid(target):
		var damage := Dice.roll(dice_amount, dice_damage)
		target.take_damage(damage, Modifier.Type.NO_MODIFIER)
	
	if current_turn >= cure_turn:
		_cure()
		
	status_applied.emit(self)
	

func _cure() -> void:
	can_expire = true
	duration = 0
