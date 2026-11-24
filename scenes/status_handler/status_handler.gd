class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)
## A status was applied to the owner (new, or more stacks/duration of an existing one).
signal status_added(status: Status)
## A status left the owner (expired, cured or removed).
signal status_removed(status: Status)
## Ward negated an incoming debuff.
signal status_absorbed(status: Status)

## Statuses Ward negates. Buffs (Attack Up, Speed Up, Thorns, Ward itself) are never absorbed.
const DEBUFF_IDS: Array[String] = ["Freeze", "Brittle", "Sunder", "Scorch", "Ashen", "SpeedDown", "AttackDown", "Poison", "Burn"]
const WARD_ID := "Ward"

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_UI = preload("res://scenes/status_handler/status_ui.tscn")
const POPUP = preload("res://scenes/ui/popup.tscn")

@export var status_owner: Node2D

var _announced_removed: Array[Status] = []


func apply_statuses_by_type(type: Status.Type) -> void:
	if type == Status.Type.EVENT_BASED:
		return
		
	var status_queue: Array[Status] = _get_all_statuses().filter(
		func(status: Status):
			return status.type == type
	)
	if status_queue.is_empty():
		statuses_applied.emit(type)
		return
	
	var tween := create_tween()
	for status: Status in status_queue:
		tween.tween_callback(status.apply_status.bind(status_owner))
		tween.tween_interval(STATUS_APPLY_INTERVAL)
	
	tween.finished.connect(func(): statuses_applied.emit(type))


func add_status(status: Status) -> void:
	var stackable := status.stack_type != Status.StackType.NONE

	if status.id in DEBUFF_IDS and _has_status(WARD_ID):
		remove_status(WARD_ID)
		_spawn_popup_text("WARD", Color.GOLD)
		status_absorbed.emit(status)
		Events.status_absorbed.emit(status_owner, status)
		return

	if not _has_status(status.id):
		var new_status_ui := STATUS_UI.instantiate() as StatusUI
		add_child(new_status_ui)
		new_status_ui.status = status
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.tree_exiting.connect(_on_status_ui_exiting.bind(status))
		new_status_ui.status.initialize_status(status_owner)
		_spawn_status_popup(status)
		_announce_added(status)
		return

	if not status.can_expire and not stackable:
		return
	
	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		_get_status(status.id).duration += status.duration
		_spawn_status_popup(status)
		_announce_added(status)
		return
	
	if status.stack_type == Status.StackType.INTENSITY:
		_get_status(status.id).stacks += status.stacks
		_spawn_status_popup(status)
		_announce_added(status)


## Removes a status by id right away. Does nothing (and emits nothing) when the owner does not have it.
func remove_status(id: String) -> void:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			remove_child(status_ui)
			status_ui.queue_free()
			_on_status_ui_exiting(status_ui.status)
			return


func _announce_added(status: Status) -> void:
	status_added.emit(status)
	Events.status_added.emit(status_owner, status)


## Runs when a status UI leaves the tree for any reason (expiry, cure, removal).
func _on_status_ui_exiting(status: Status) -> void:
	if status == null or _announced_removed.has(status):
		return
	_announced_removed.append(status)
	if not is_instance_valid(status_owner) or status_owner.is_queued_for_deletion():
		return
	status_removed.emit(status)
	Events.status_removed.emit(status_owner, status)


func _has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true
			
	return false


func _get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status
	
	return null


func _get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
		
	return statuses


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.status_tooltip_requested.emit(_get_all_statuses())


func _spawn_popup_text(text: String, color: Color) -> void:
	if not is_instance_valid(status_owner) or not is_inside_tree():
		return
	var popup := POPUP.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = status_owner.global_position
	popup.setup(text, color, status_owner.get_instance_id())


func _spawn_status_popup(status: Status) -> void:
	var popup := POPUP.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = status_owner.global_position
	popup.setup(status.name.to_upper(), Color.GOLD, status_owner.get_instance_id())
