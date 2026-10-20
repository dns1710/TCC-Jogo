class_name Campfire
extends Control

@export var char_stats: CharacterStats

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rest_button: Button = %RestButton


func _on_rest_button_pressed() -> void:
	rest_button.disabled = true
	var previous_health: int = char_stats.health
	
	char_stats.heal(ceili(char_stats.max_health * 0.3))
	
	var healed_amount: int = char_stats.health - previous_health
	
	if healed_amount > 0:
		var max_healing: float = char_stats.max_health*0.3
		
		
	animation_player.play("fade_out")


func _on_fade_out_finished() -> void:
	Events.campfire_exited.emit()
