class_name RelicUI
extends Control

@export var relic: Relic : set = set_relic

@onready var icon: TextureRect = $Icon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var hover_tooltip: HoverTooltip

func _ready() -> void:
	hover_tooltip = get_tree().get_first_node_in_group("global_tooltip") as HoverTooltip

func set_relic(new_relic: Relic) -> void:
	if not is_node_ready():
		await ready

	relic = new_relic
	icon.texture = relic.icon


func flash() -> void:
	animation_player.play("flash")


func _on_mouse_entered() -> void:
	if not relic or not hover_tooltip:
		return
	hover_tooltip.show_tooltip(relic.relic_name, relic.get_rarity(), relic.get_equip(), relic.get_tooltip())

func _on_mouse_exited() -> void:
	if hover_tooltip:
		hover_tooltip.hide_tooltip()
		
#func _on_gui_input(event: InputEvent) -> void:
#	if event.is_action_pressed("left_mouse"):
#		Events.relic_tooltip_requested.emit(relic)
