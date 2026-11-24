extends Node
## Headless check of the combat-text cascade: popups that belong to one actor stack in
## separate lines instead of overlapping, and different actors do not push each other.
## Run: Godot --headless --path . res://tools/verify_popup_cascade.tscn

const POPUP := preload("res://scenes/ui/popup.tscn")

var _errors: Array[String] = []


func _ready() -> void:
	var host := Node2D.new()
	add_child(host)
	var first := _spawn(host, "12", Vector2(100, 80), 1)
	var second := _spawn(host, "BRITTLE", Vector2(100, 80), 1)
	var third := _spawn(host, "7", Vector2(100, 80), 1)
	var other := _spawn(host, "5", Vector2(100, 80), 2)
	await get_tree().create_timer(0.3).timeout
	var ys := [third.global_position.y, second.global_position.y, first.global_position.y]
	_expect(ys[0] - ys[1] >= PopUp.LINE_HEIGHT - 1.0 and ys[1] - ys[2] >= PopUp.LINE_HEIGHT - 1.0,
		"popups of one actor must be at least one line apart, got %s" % [ys])
	_expect(ys[0] > ys[1] and ys[1] > ys[2], "newest popup should sit lowest, oldest highest, got %s" % [ys])
	_expect(absf(other.global_position.y - third.global_position.y) < 1.0, "a popup of another actor was pushed")
	# After they fade the registry is empty again.
	await get_tree().create_timer(1.4).timeout
	_expect(PopUp._live.is_empty(), "popup registry still holds %d anchors" % PopUp._live.size())

	if _errors.is_empty():
		print("POPUP CASCADE CHECK OK")
		get_tree().quit(0)
	else:
		print("POPUP CASCADE CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _spawn(host: Node, text: String, at: Vector2, anchor: int) -> PopUp:
	var popup := POPUP.instantiate() as PopUp
	host.add_child(popup)
	popup.global_position = at
	popup.setup(text, Color.WHITE, anchor)
	return popup


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
