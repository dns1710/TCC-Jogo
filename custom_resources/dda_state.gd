class_name DDAState
extends Resource
## The difficulty adjustment's per-run memory. Lives on RunStats, so it is saved
## and restored with the run. Flags reset at the start of every act.

const MAX_HISTORY := 100

## The once-per-act shop swap has been used.
@export var shop_changed := false
## A treasure room was just left; the next map view checks for conversions.
@export var treasure_pending := false
## Relic count when the player entered the last shop or treasure room.
@export var shop_entered_items := 0
## HP share when the player arrived at the current campfire, before resting.
@export var campfire_arrival_hp := 1.0
## Every score change with its reason, newest last (capped).
@export var history: Array[String] = []


func reset_for_act() -> void:
	shop_changed = false
	treasure_pending = false
	shop_entered_items = 0


func record(reason: String, amount: int, new_score: int) -> void:
	history.append("%s %+d -> %d" % [reason, amount, new_score])
	if history.size() > MAX_HISTORY:
		history = history.slice(history.size() - MAX_HISTORY)
