class_name StatusUI
extends Control

@export var status: Status : set = set_status

@onready var icon: TextureRect = $Icon
@onready var duration: Label = $Duration
@onready var stacks: Label = $Stacks

var hover_tooltip = HoverTooltip

func _ready() -> void:
	hover_tooltip = get_tree().get_first_node_in_group("global_tooltip") as HoverTooltip
	
func set_status(new_status: Status) -> void:
	if not is_node_ready():
		await ready
	
	status = new_status
	icon.texture = status.icon
	duration.visible = status.stack_type == Status.StackType.DURATION
	stacks.visible = status.stack_type == Status.StackType.INTENSITY
	custom_minimum_size = icon.size
	
	if duration.visible:
		custom_minimum_size = duration.size + duration.position
	elif stacks.visible:
		custom_minimum_size = stacks.size + stacks.position
	
	if not status.status_changed.is_connected(_on_status_changed):
		status.status_changed.connect(_on_status_changed)
	
	_on_status_changed()


func _on_status_changed() -> void:
	if not status:
		return

	if status.can_expire and status.duration <= 0:
		queue_free()
		
	if status.stack_type == Status.StackType.INTENSITY and status.stacks == 0:
		queue_free()

	duration.text = str(status.duration)
	stacks.text = str(status.stacks)
	

func _on_mouse_entered() -> void:
	if not status or not hover_tooltip:
		return
	hover_tooltip.show_tooltip(status.name, status.get_tooltip())

func _on_mouse_exited() -> void:
	if hover_tooltip:
		hover_tooltip.hide_tooltip()
