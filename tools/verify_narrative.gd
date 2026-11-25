extends Node
## Headless check of the scoutmaster-narrative spec: DDA.execute emits dda_adjusted with
## the right direction, the banner shows one non-repeating line when the room change
## becomes visible and drops stale remarks, the opening is skippable and routed only for
## a New Run, and the win screen ending sequence reaches the same end state whether it
## plays out or is skipped.
## Run: Godot --headless --path . res://tools/verify_narrative.tscn

const LINES_PATH := "res://scenes/narrative/scoutmaster_lines.tres"
const OPENING_PATH := "res://scenes/narrative/opening.tscn"
const WIN_PATH := "res://scenes/win_screen/win_screen.tscn"
const RAIN_PATH := "res://scenes/narrative/rain_backdrop.tscn"
const MENU_PATH := "res://scenes/ui/main_menu.tscn"
const RUN_PATH := "res://scenes/run/run.tscn"
const PLAYER_PATH := "res://characters/player/player.tres"

var _errors: Array[String] = []
var _adjusted: Array[bool] = []


class FakeMap:
	extends Object
	var changed_count := 1

	func convert_rooms(_from: int, _to: int, _count: int) -> Array:
		var result: Array = []
		for i in changed_count:
			result.append(i)
		return result


func _ready() -> void:
	# battle_start would open the first-battle tutorial and pause the tree.
	TutorialManager.disable_auto_show()
	Events.dda_adjusted.connect(func(harder: bool): _adjusted.append(harder))
	_check_signal()
	_check_lines()
	await _check_banner()
	await _check_rain()
	await _check_opening()
	_check_menu_routing()
	await _check_win_screen()

	if _errors.is_empty():
		print("NARRATIVE CHECK OK")
		get_tree().quit(0)
	else:
		print("NARRATIVE CHECK FAILED")
		for e in _errors:
			print("  ", e)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _check_signal() -> void:
	var dda := DDA.new()
	var state := DDAState.new()
	var map := FakeMap.new()

	_adjusted.clear()
	dda.execute([DDAConversion.make(Room.Type.SHOP, Room.Type.MONSTER)], map, state)
	_expect(_adjusted == [true], "conversion to a battle emits dda_adjusted(true), got %s" % [_adjusted])

	_adjusted.clear()
	dda.execute([DDAConversion.make(Room.Type.MONSTER, Room.Type.CAMPFIRE)], map, state)
	_expect(_adjusted == [false], "conversion to a campfire emits dda_adjusted(false), got %s" % [_adjusted])

	_adjusted.clear()
	dda.execute([
		DDAConversion.make(Room.Type.MONSTER, Room.Type.CAMPFIRE),
		DDAConversion.make(Room.Type.SHOP, Room.Type.MONSTER),
	], map, state)
	_expect(_adjusted == [true], "harder wins when both happen in one call, got %s" % [_adjusted])

	_adjusted.clear()
	map.changed_count = 0
	dda.execute([DDAConversion.make(Room.Type.SHOP, Room.Type.MONSTER)], map, state)
	dda.execute([], map, state)
	_expect(_adjusted.is_empty(), "no changed room emits nothing, got %s" % [_adjusted])
	map.free()


func _check_lines() -> void:
	var lines = load(LINES_PATH)
	_expect(lines != null, "lines resource exists")
	if lines == null:
		return
	_expect(lines.harder.size() >= 3, "at least 3 harder lines")
	_expect(lines.easier.size() >= 3, "at least 3 easier lines")
	_expect(lines.opening.size() >= 1 and lines.opening.size() <= 4, "opening has at most 4 lines")
	_expect(lines.epilogue.size() >= 1 and lines.epilogue.size() <= 3, "epilogue has at most 3 lines")
	for line in lines.harder + lines.easier:
		_expect(not String(line).contains("\n"), "remark is one line: %s" % line)


func _check_banner() -> void:
	var banner = get_node_or_null("/root/ScoutmasterBanner")
	_expect(banner != null, "ScoutmasterBanner autoload exists")
	if banner == null:
		return
	var lines = load(LINES_PATH)

	# The signal checks above left a pending remark; a battle start clears it.
	Events.battle_start.emit()
	banner.dismiss()
	Events.animation_dda_lock.emit(true)
	_expect(not banner.is_showing(), "no remark without a pending adjustment")
	Events.animation_dda_lock.emit(false)

	Events.dda_adjusted.emit(true)
	_expect(not banner.is_showing(), "remark waits for the animation")
	Events.animation_dda_lock.emit(true)
	_expect(banner.is_showing(), "remark shows when the animation starts")
	_expect(banner.current_line in lines.harder, "harder adjustment shows a harder line")
	_expect(not banner.current_line.contains("\n"), "remark is one line")
	banner.dismiss()
	_expect(not banner.is_showing(), "dismiss hides the remark")
	Events.animation_dda_lock.emit(false)

	Events.dda_adjusted.emit(false)
	Events.animation_dda_lock.emit(true)
	_expect(banner.current_line in lines.easier, "easier adjustment shows an easier line")
	banner.dismiss()
	Events.animation_dda_lock.emit(false)

	# The latest direction replaces a pending one.
	Events.dda_adjusted.emit(true)
	Events.dda_adjusted.emit(false)
	Events.animation_dda_lock.emit(true)
	_expect(banner.current_line in lines.easier, "latest direction wins")
	banner.dismiss()
	Events.animation_dda_lock.emit(false)

	# Never the same line twice in a row.
	var previous := ""
	var repeated := false
	for i in 30:
		Events.dda_adjusted.emit(true)
		Events.animation_dda_lock.emit(true)
		if banner.current_line == previous:
			repeated = true
		previous = banner.current_line
		banner.dismiss()
		Events.animation_dda_lock.emit(false)
	_expect(not repeated, "the same line never appears twice in a row")

	# A pending remark that never got an animation is dropped at battle start.
	Events.dda_adjusted.emit(true)
	Events.battle_start.emit()
	Events.animation_dda_lock.emit(true)
	_expect(not banner.is_showing(), "stale remark dropped at battle_start")
	Events.animation_dda_lock.emit(false)

	# It must not block input.
	Events.dda_adjusted.emit(true)
	Events.animation_dda_lock.emit(true)
	for node in banner.find_children("*", "Control", true, false):
		_expect((node as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "banner control ignores the mouse: %s" % node.name)
	banner.dismiss()
	Events.animation_dda_lock.emit(false)
	await get_tree().process_frame


func _check_rain() -> void:
	var packed = load(RAIN_PATH)
	_expect(packed != null, "rain backdrop scene exists")
	if packed == null:
		return
	var rain = packed.instantiate()
	add_child(rain)
	await get_tree().process_frame
	_expect(rain.is_raining(), "rain starts falling")
	rain.stop_rain(0.0)
	_expect(not rain.is_raining(), "stop_rain(0) stops it at once")
	rain.queue_free()


func _check_opening() -> void:
	var packed = load(OPENING_PATH)
	_expect(packed != null, "opening scene exists")
	if packed == null:
		return
	var opening = packed.instantiate()
	opening.auto_start_run = false
	add_child(opening)
	await get_tree().process_frame
	var lines = load(LINES_PATH)
	_expect(opening.line_count() == lines.opening.size() and opening.line_count() <= 4, "opening shows at most 4 lines")
	var finished := [0]
	opening.finished.connect(func(): finished[0] += 1)
	opening.skip()
	_expect(finished[0] == 1, "skip finishes the opening")
	opening.skip()
	_expect(finished[0] == 1, "finishing twice emits once")
	opening.queue_free()


func _check_menu_routing() -> void:
	var menu = (load(MENU_PATH) as PackedScene).instantiate()
	var new_scene: PackedScene = menu.scene_for(RunStartup.Type.NEW_RUN)
	var continued_scene: PackedScene = menu.scene_for(RunStartup.Type.CONTINUED_RUN)
	_expect(new_scene.resource_path == OPENING_PATH, "New Run goes through the opening")
	_expect(continued_scene.resource_path == RUN_PATH, "Continue goes straight to the run")
	menu.free()


func _check_win_screen() -> void:
	var packed: PackedScene = load(WIN_PATH)
	var character: CharacterStats = load(PLAYER_PATH)
	for skipped in [true, false]:
		var label := "skipped" if skipped else "played"
		var win = packed.instantiate()
		win.autoplay = false
		add_child(win)
		win.character = character.create_instance()
		await get_tree().process_frame

		_expect(not win.exit_button().visible, "%s: exit button hidden before the sequence" % label)
		_expect(win.epilogue_line_count() >= 1 and win.epilogue_line_count() <= 3, "%s: epilogue has 1 to 3 lines" % label)
		var finished := [0]
		win.finished.connect(func(): finished[0] += 1)

		if not skipped:
			win.time_scale = 100.0
		win.play()
		if skipped:
			await get_tree().create_timer(0.05).timeout
			_expect(not win.exit_button().visible, "%s: button hidden while the sequence runs" % label)
			win.skip()
		else:
			await win.finished

		_expect(finished[0] == 1, "%s: finished emitted once, got %d" % [label, finished[0]])
		_expect(win.exit_button().visible and win.exit_button().modulate.a >= 0.99, "%s: exit button shown" % label)
		_expect(not win.is_raining(), "%s: rain stopped" % label)
		_expect(win.epilogue_fully_shown(), "%s: full epilogue shown" % label)
		_expect(win.portrait_dimmed(), "%s: portrait dimmed" % label)
		win.skip()
		_expect(finished[0] == 1, "%s: skip after the end does not emit again" % label)
		win.queue_free()
		await get_tree().process_frame
