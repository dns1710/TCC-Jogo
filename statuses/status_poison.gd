class_name StatusPoison
extends Status

@export var dice_amount := 1
@export var dice_damage := 4
@export var cure_turn := 3
@export_range(0.0,1.0) var cure_chance := 0.5
var current_turn := 0

func apply_status(target: Node) -> void:
	current_turn += 1
	
	if current_turn >= cure_turn and randf() <= cure_chance:
		_cure()
		return
		
	if is_instance_valid(target):
		var damage := Dice.roll(dice_amount, dice_damage)
		target.take_damage(damage, Modifier.Type.NO_MODIFIER)
	
	status_applied.emit(self)
	

func _cure() -> void:
	can_expire = true
	duration = 0
