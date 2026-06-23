class_name HelpfulBoiEvent
extends EventRoom

@onready var plus_max_hp_button: EventRoomButton = %PlusMaxHPButton


func _ready() -> void:
	plus_max_hp_button.event_button_callback = plus_max_hp




func plus_max_hp() -> void:
	character_stats.max_health += 5
