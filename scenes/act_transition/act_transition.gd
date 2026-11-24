class_name ActTransition
extends Control
## Shown after an act boss falls: the finished act's lore, then the next act.

@onready var title_label: Label = %Title
@onready var body_label: Label = %Body
@onready var next_label: Label = %Next
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)


func setup(finished_act: Act, next_act: Act) -> void:
	title_label.text = "%s cleared" % finished_act.act_name
	body_label.text = finished_act.transition_text
	next_label.text = "Next: %s" % next_act.act_name


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	Events.act_transition_finished.emit()
