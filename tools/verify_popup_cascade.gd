extends Node
## Headless check of the Fortnite-style combat text: popups of one actor start a short time apart,
## drift to alternating sides and grow while they drift out, a third popup rises above the first,
## numbers grow with their size, a different actor is not delayed, and the registry empties afterwards.
## Run: Godot --headless --path . res://tools/verify_popup_cascade.tscn

const POPUP := preload("res://scenes/ui/popup.tscn")

var _errors: Array[String] = []


func _ready() -> void:
	# Let the first, slow frames pass so tween timing is realistic.
	for i in 5:
		await get_tree().process_frame
	var host := Node2D.new()
	add_child(host)
	var first := _spawn(host, "12", Vector2(100, 80), 1)
	var second := _spawn(host, "7", Vector2(100, 80), 1)
	var third := _spawn(host, "BRITTLE", Vector2(100, 80), 1)
	var other := _spawn(host, "5", Vector2(100, 80), 2)

	# Scheduling: one slot apart for the same actor, none for another actor.
	_expect(is_zero_approx(first.start_delay), "the first popup starts at once, delay %.3f" % first.start_delay)
	_expect(absf(second.start_delay - PopUp.STAGGER) < 0.02, "the second waits one stagger, delay %.3f" % second.start_delay)
	_expect(absf(third.start_delay - 2.0 * PopUp.STAGGER) < 0.03, "the third waits two staggers, delay %.3f" % third.start_delay)
	_expect(other.start_delay < 0.02, "another actor is not delayed, delay %.3f" % other.start_delay)
	_expect(first.side != second.side and first.side == third.side, "popups alternate sides")

	# While the second popup is waiting it is invisible; the first is already showing.
	await get_tree().create_timer(0.07).timeout
	_expect(first.modulate.a > 0.3, "the first popup is already showing, alpha %.2f" % first.modulate.a)
	_expect(second.modulate.a == 0.0 and third.modulate.a == 0.0, "later popups are still waiting")

	# Grow while drifting out: the first popup is bigger and further from the actor later on.
	var early_scale := first.scale.x
	var early_distance := first.offset.length()
	await get_tree().create_timer(0.2).timeout
	_expect(first.scale.x > early_scale and first.offset.length() > early_distance, "the number grows while it drifts away")
	_expect(first.scale.x > 1.0, "the number is bigger than its base size, got %.2f" % first.scale.x)

	# Everyone has settled: opposite sides apart, the third above the first, numbers grow with size.
	await get_tree().create_timer(0.55).timeout
	_expect(second.drift.x * first.drift.x < 0.0, "the second popup drifts to the other side")
	_expect(third.drift.y <= first.drift.y - PopUp.LEVEL_RISE * 0.6, "the third popup rises above the first (%.1f vs %.1f)" % [third.drift.y, first.drift.y])
	_expect(first.end_scale > second.end_scale and second.end_scale > third.end_scale, "bigger numbers grow bigger, status names stay smaller")

	# After they fade the registry is empty again.
	await get_tree().create_timer(1.2).timeout
	_expect(PopUp._live.is_empty() and PopUp._next_start.is_empty() and PopUp._started.is_empty(), "popup registry still holds %d anchors" % PopUp._live.size())

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
