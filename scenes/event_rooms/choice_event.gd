class_name ChoiceEvent
extends EventRoom
## Plays any EventDefinition: shows its text and choices, then an outcome screen
## (result text, effect lines, Continue) before returning to the map.

@onready var title_label: Label = %Title
@onready var body_label: Label = %Body
@onready var choices_box: VBoxContainer = %Choices
@onready var result_box: VBoxContainer = %Result
@onready var result_label: Label = %ResultText
@onready var effects_box: VBoxContainer = %Effects
@onready var continue_button: Button = %ContinueButton

const GAIN_COLOR := Color(0.6, 1.0, 0.6)
const LOSS_COLOR := Color(1.0, 0.5, 0.5)
const NEUTRAL_COLOR := Color(1.0, 0.85, 0.4)

var buttons: Array[Button] = []
var chosen := false
## The effect lines shown on the outcome screen (for example "-50 gold").
var effect_lines: Array[String] = []


func setup() -> void:
	if definition == null:
		push_warning("ChoiceEvent has no event definition.")
		Events.event_room_exited.emit()
		return

	title_label.text = definition.title
	body_label.text = definition.body
	result_box.hide()

	for i in definition.choices.size():
		var choice := definition.choices[i]
		var button := Button.new()
		button.text = choice.label
		button.custom_minimum_size = Vector2(0, 15)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not choice.can_afford(character_stats, run_stats)
		button.pressed.connect(choose.bind(i))
		choices_box.add_child(button)
		buttons.append(button)

	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)


## Plays out a choice. Public so tests can drive it without clicking.
func choose(index: int) -> void:
	if chosen or index < 0 or index >= definition.choices.size():
		return

	var choice := definition.choices[index]
	if not choice.can_afford(character_stats, run_stats):
		return
	chosen = true

	var bet := choice.bet(run_stats)
	var lines := choice.pay(self)
	var outcome := choice.pick_outcome(character_stats)
	if outcome:
		lines.append_array(outcome.apply(self, bet))
		result_label.text = outcome.text
	else:
		result_label.text = ""

	_show_effects(lines)

	body_label.hide()
	choices_box.hide()
	result_box.show()
	continue_button.grab_focus()


func _show_effects(lines: Array[String]) -> void:
	effect_lines = lines
	for child in effects_box.get_children():
		child.queue_free()

	for line in lines:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", _line_color(line))
		effects_box.add_child(label)
	effects_box.visible = not lines.is_empty()


## Gains are green, losses red, anything else (found relic, room change) gold.
static func _line_color(line: String) -> Color:
	if line.begins_with("+"):
		return GAIN_COLOR
	if line.begins_with("-"):
		return LOSS_COLOR
	return NEUTRAL_COLOR


func _on_continue_pressed() -> void:
	Events.event_room_exited.emit()
