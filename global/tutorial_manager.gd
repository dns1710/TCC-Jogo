extends Node
## Autoload. Shows the tutorial overlay once, at the first battle ever started on this
## machine, and again whenever Events.tutorial_requested is emitted. It listens to
## Events.battle_start, so battle.gd does not need to know about the tutorial.
##
## "Seen" is stored in user://settings.cfg ([tutorial] seen). If the file cannot be
## written, the in-memory flag still limits the automatic show to once per session.

const OVERLAY_SCENE := preload("res://scenes/tutorial/tutorial_overlay.tscn")
const SECTION := "tutorial"
const KEY := "seen"

## Overridable so tests never touch the real settings file.
var settings_path := "user://settings.cfg"

var _shown_this_session := false
var _overlay: TutorialOverlay = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.battle_start.connect(_on_battle_start)
	Events.tutorial_requested.connect(show_tutorial)


func has_seen() -> bool:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return false
	return config.get_value(SECTION, KEY, false)


func mark_seen() -> void:
	var config := ConfigFile.new()
	config.load(settings_path) # keep other settings if the file already exists
	config.set_value(SECTION, KEY, true)
	if config.save(settings_path) != OK:
		push_warning("Could not save %s; the tutorial will not repeat this session." % settings_path)


func is_open() -> bool:
	return is_instance_valid(_overlay)


## For automated battles: stops the first-battle tutorial from pausing the game.
func disable_auto_show() -> void:
	_shown_this_session = true


func reset_for_tests() -> void:
	_shown_this_session = false
	if is_open():
		_overlay.queue_free()
	_overlay = null


## Shows the tutorial now. `automatic` true means it was the first-battle show, which
## records the tutorial as seen when it closes; a replay never changes the record.
func show_tutorial(automatic := false) -> void:
	if is_open():
		return
	_overlay = OVERLAY_SCENE.instantiate() as TutorialOverlay
	_overlay.closed.connect(_on_overlay_closed.bind(automatic))
	# Deferred: the root may be busy setting up children when a scene calls this from _ready.
	get_tree().root.add_child.call_deferred(_overlay)
	_overlay.open.call_deferred()


func _on_battle_start() -> void:
	if has_seen() or _shown_this_session:
		return
	_shown_this_session = true
	# Deferred: Battle.start_battle unpauses the tree right after emitting this signal.
	show_tutorial.call_deferred(true)


func _on_overlay_closed(automatic: bool) -> void:
	_overlay = null
	if automatic:
		mark_seen()
	Events.tutorial_finished.emit()
