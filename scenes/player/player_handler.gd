class_name PlayerHandler 
extends Node

@export var relics: RelicHandler 
@export var player: Player

var character: CharacterStats 

func start_battle(char_stats: CharacterStats) -> void: 
	character = char_stats 
	relics.relics_activated.connect(_on_relics_activated) 
	start_turn() 

func start_turn() -> void: 
	character.reset_mana() 
	relics.activate_relics_by_type(Relic.Type.START_OF_TURN) 

func end_turn() -> void: 
	relics.activate_relics_by_type(Relic.Type.END_OF_TURN) 

func _on_relics_activated(type: Relic.Type) -> void: 
	match type: 
		Relic.Type.START_OF_TURN: 
			player.status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN) 
		Relic.Type.END_OF_TURN: 
			player.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)
