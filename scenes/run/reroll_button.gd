extends Button

signal reroll_pressed

func _ready() -> void:
	text = "Reroll"
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	reroll_pressed.emit()
