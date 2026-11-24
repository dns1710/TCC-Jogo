extends Node
## Headless check of the first-run-tutorial spec: automatic show once, skip and finish,
## replay, pause and restore, unwritable settings, page limits, menu buttons.
## Run: Godot --headless --path . res://tools/verify_tutorial.tscn

const TEST_SETTINGS := "user://test_tutorial_settings.cfg"
const UNWRITABLE := "user://no_such_dir/settings.cfg"

var _errors: Array[String] = []
var _real_path := ""


func _ready() -> void:
	_real_path = TutorialManager.settings_path
	await _run_checks()
	TutorialManager.settings_path = _real_path
	TutorialManager.reset_for_tests()
	get_tree().paused = false
	_delete_test_file()
	if _errors.is_empty():
		print("TUTORIAL CHECK OK")
		get_tree().quit(0)
	else:
		print("TUTORIAL CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _fresh(path := TEST_SETTINGS) -> void:
	TutorialManager.reset_for_tests()
	_delete_test_file()
	TutorialManager.settings_path = path
	get_tree().paused = false


func _overlay() -> TutorialOverlay:
	return TutorialManager._overlay


func _run_checks() -> void:
	_expect(TutorialOverlay.PAGES.size() <= 5 and TutorialOverlay.PAGES.size() >= 1, "tutorial must have 1 to 5 pages")
	_expect(TutorialManager.get_node_or_null(".") != null and Events.has_signal("tutorial_requested") and Events.has_signal("tutorial_finished"), "Events must have the tutorial signals")

	# First battle ever: shows, pauses, and skipping records it as seen.
	_fresh()
	_expect(not TutorialManager.has_seen(), "a missing settings file means not seen")
	Events.battle_start.emit()
	await _frames()
	_expect(TutorialManager.is_open(), "tutorial must show at the first battle")
	_expect(get_tree().paused, "the tree must be paused while the tutorial is open")
	if TutorialManager.is_open():
		var overlay := _overlay()
		_expect(overlay.page_label.text == "1/%d" % TutorialOverlay.PAGES.size(), "page counter must show the first page")
		_expect(overlay.back_button.disabled, "Back must be disabled on page 1")
		overlay.skip_button.pressed.emit()
	await _frames()
	_expect(not TutorialManager.is_open(), "skip must close the tutorial")
	_expect(not get_tree().paused, "closing must resume the game")
	_expect(TutorialManager.has_seen(), "skip must record the tutorial as seen")

	# Later battles do not show it again.
	Events.battle_start.emit()
	await _frames()
	_expect(not TutorialManager.is_open(), "no tutorial at later battles")
	TutorialManager.reset_for_tests()
	Events.battle_start.emit()
	await _frames()
	_expect(not TutorialManager.is_open(), "no tutorial in a later session once seen")

	# Replay on request: pages step through, finish closes, the record is unchanged.
	Events.tutorial_requested.emit()
	await _frames()
	_expect(TutorialManager.is_open(), "replay must show the tutorial even when seen")
	if TutorialManager.is_open():
		var overlay := _overlay()
		for i in TutorialOverlay.PAGES.size() - 1:
			overlay.next_button.pressed.emit()
			await _frames(1)
		_expect(overlay.page == TutorialOverlay.PAGES.size() - 1, "Next must reach the last page")
		_expect(overlay.next_button.text == "Done", "the last page must offer Done")
		overlay.back_button.pressed.emit()
		_expect(overlay.page == TutorialOverlay.PAGES.size() - 2, "Back must go to the previous page")
		overlay.next_button.pressed.emit()
		overlay.next_button.pressed.emit()
	await _frames()
	_expect(not TutorialManager.is_open(), "Done must close the tutorial")
	_expect(TutorialManager.has_seen(), "replay must leave the seen record as it was")

	# Replay when never seen does not mark it seen; the first battle still shows it.
	_fresh()
	Events.tutorial_requested.emit()
	await _frames()
	_expect(TutorialManager.is_open(), "replay must work when never seen")
	if TutorialManager.is_open():
		_overlay().close()
	await _frames()
	_expect(not TutorialManager.has_seen(), "a replay must not mark the tutorial as seen")
	Events.battle_start.emit()
	await _frames()
	_expect(TutorialManager.is_open(), "the first battle still shows it after a replay")
	if TutorialManager.is_open():
		_overlay().close()
	await _frames()

	# The previous paused state is restored (for example from the pause menu).
	_fresh()
	get_tree().paused = true
	Events.tutorial_requested.emit()
	await _frames()
	_expect(get_tree().paused, "still paused while open")
	if TutorialManager.is_open():
		_overlay().close()
	await _frames()
	_expect(get_tree().paused, "closing must restore the earlier paused state (true)")
	get_tree().paused = false

	# Opening twice does not stack overlays.
	_fresh()
	Events.tutorial_requested.emit()
	Events.tutorial_requested.emit()
	await _frames()
	var count := 0
	for child in get_tree().root.get_children():
		if child is TutorialOverlay:
			count += 1
	_expect(count == 1, "only one overlay may exist, found %d" % count)
	if TutorialManager.is_open():
		_overlay().close()
	await _frames()

	# Unwritable settings: at most one automatic show per session.
	_fresh(UNWRITABLE)
	Events.battle_start.emit()
	await _frames()
	_expect(TutorialManager.is_open(), "unwritable settings still show it the first time")
	if TutorialManager.is_open():
		_overlay().close()
	await _frames()
	_expect(not TutorialManager.has_seen(), "nothing could be saved")
	Events.battle_start.emit()
	await _frames()
	_expect(not TutorialManager.is_open(), "no second automatic show in the same session")

	# The tutorial never touches battle state: no turn bar code runs while paused.
	_fresh()
	var atb_node := Node.new()
	atb_node.set_script(preload("res://tools/verify_tutorial_probe.gd"))
	add_child(atb_node)
	Events.battle_start.emit()
	await _frames()
	var before: int = atb_node.ticks
	await _frames(10)
	_expect(atb_node.ticks == before, "pausable nodes must not process while the tutorial is open")
	if TutorialManager.is_open():
		_overlay().close()
	await _frames()
	_expect(atb_node.ticks > before, "pausable nodes resume after closing")
	atb_node.queue_free()

	# Entry points exist in the scenes.
	var menu_state := (load("res://scenes/ui/main_menu.tscn") as PackedScene).get_state()
	var menu_nodes: Array[String] = []
	for i in menu_state.get_node_count():
		menu_nodes.append(str(menu_state.get_node_name(i)))
	_expect(menu_nodes.has("Tutorial"), "main menu must have a Tutorial button")
	var run_state := (load("res://scenes/run/run.tscn") as PackedScene).get_state()
	var run_nodes: Array[String] = []
	for i in run_state.get_node_count():
		run_nodes.append(str(run_state.get_node_name(i)))
	_expect(run_nodes.has("TutorialButton"), "pause menu must have a Tutorial button")
