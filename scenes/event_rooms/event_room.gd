class_name EventRoom
extends Control

@export var character_stats: CharacterStats
@export var run_stats: RunStats

## The event being played (set by the run before setup()).
var definition: EventDefinition
## Hooks for effects that reach beyond stats; may be null in tests.
var relic_handler: RelicHandler
var map: Node
var relic_pool: Array[Relic] = []


func setup() -> void:
	pass
