class_name Player extends Node2D 
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres") 

@export var stats: CharacterStats : set = set_character_stats 
@onready var sprite_2d: Sprite2D = $Sprite2D 
@onready var stats_ui: StatsUI = $StatsUI 
@onready var status_handler: StatusHandler = $StatusHandler 
@onready var modifier_handler: ModifierHandler = $ModifierHandler
@onready var atb_progress: TextureProgressBar = $ATBProgress

const DAMAGE_POPUP = preload("res://scenes/ui/popup.tscn")
const ATB_MAX := 30.0

var atb: float = 0.0
var can_act := false

func _ready() -> void: 
	status_handler.status_owner = self
	atb_progress.min_value = 0
	atb_progress.max_value = ATB_MAX
	
func reset_atb() -> void:
	atb = 0.0
	can_act = false
	atb_progress.value = atb

func add_atb(delta: float) -> void:
	if can_act:
		return
	atb += stats.speed * delta
	
	if atb >= ATB_MAX:
		atb = ATB_MAX
		can_act = true
	atb_progress.value = atb

func set_character_stats(value: CharacterStats) -> void:
	stats = value 
	if not stats.stats_changed.is_connected(update_stats): 
		stats.stats_changed.connect(update_stats) 
	update_player() 

func update_player() -> void: 
	if not stats is CharacterStats: 
		return 
	
	if not is_inside_tree(): 
		await ready
	
	sprite_2d.texture = stats.art
	update_stats() 

func update_stats() -> void: 
	stats_ui.update_stats(stats) 

func take_damage(damage: int, which_modifier: Modifier.Type, source = null) -> void: 
	if stats.health <= 0: 
		return 
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL 
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier) 
	_spawn_popup(str(modified_damage), Color.FIREBRICK)
	var tween := create_tween() 
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15)) 
	tween.tween_callback(stats.take_damage.bind(modified_damage)) 
	tween.tween_interval(0.17)
	Events.player_damaged.emit(source, modified_damage)
	tween.finished.connect( 
		func(): 
			sprite_2d.material = null 
			if stats.health <= 0: 
				Events.player_died.emit() 
				queue_free() 
	)

func heal(amount:int) -> void:
	stats.heal(amount)
	_spawn_popup(str(amount), Color.LIME_GREEN)

func _spawn_popup(poptext: String, color: Color) -> void:
	var popup = DAMAGE_POPUP.instantiate()
	var random_offset = Vector2(randf_range(-10, 10), 0)
	get_parent().add_child(popup)
	popup.global_position = sprite_2d.global_position + random_offset
	popup.setup(poptext, color)
