class_name Treasure
extends Control

@export var treasure_relic_pool: Array[Relic]
@export var relic_handler: RelicHandler
@export var char_stats: CharacterStats

@onready var animation_player: AnimationPlayer = %AnimationPlayer
var found_relic: Relic


func generate_relic() -> void:
	var available_relics: Dictionary = {
		Relic.Rarity.UNCOMMON: [],
		Relic.Rarity.RARE: []
	}
	
	for relic: Relic in treasure_relic_pool:
		if relic == null:
			continue
		if not relic.can_appear_as_reward(char_stats):
			continue
		if relic_handler.has_relic(relic.id):
			continue
		if relic.rarity == Relic.Rarity.COMMON:
			continue
		
		available_relics[relic.rarity].append(relic)
	
	var rarity_weights: Dictionary = {
		Relic.Rarity.UNCOMMON: 60,
		Relic.Rarity.RARE: 40
	}
	
	var total_weight := 0
	var available_rarities: Array[int] = []
	
	for rarity: int in rarity_weights:
		if not available_relics[rarity].is_empty():
			available_rarities.append(rarity)
			total_weight += rarity_weights[rarity]
	
	if available_rarities.is_empty():
		found_relic = null
	
	var roll := RNG.pick_random(1,total_weight)
	
	for rarity: int in available_rarities:
		roll -= rarity_weights[rarity]
		if roll <= 0:
			found_relic = RNG.array_pick_random(available_relics[rarity])
			break
	print("POOL SIZE:", treasure_relic_pool.size())
	print("FOUND RELIC:", found_relic.relic_name)
	
	
func _on_treasure_opened() -> void:
	Events.treasure_room_exited.emit(found_relic)


func _on_treasure_chest_gui_input(event: InputEvent) -> void:
	if animation_player.current_animation == "open":
		return
	
	if event.is_action_pressed("left_mouse"):
		animation_player.play("open")
