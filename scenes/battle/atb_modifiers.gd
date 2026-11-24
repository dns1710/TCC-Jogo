class_name ATBModifiers
extends RefCounted
## Turn-bar rate factors tracked per source, plus Freeze timing.
## The actor's rate multiplier is the product of every factor, so one effect
## ending never cancels another. Freeze and its immunity are measured in battle
## time through tick(), which the actor calls from add_atb (only while the battle runs).

signal freeze_ended

const FREEZE_TIME := 1.5
const FREEZE_IMMUNITY := 4.0
const FREEZE_SOURCE := "freeze"

## Permanent immunity, for bosses.
var freeze_immune := false
var freeze_left := 0.0
var immunity_left := 0.0

var _factors := {}


func set_factor(source: String, factor: float) -> void:
	_factors[source] = factor


func clear_factor(source: String) -> void:
	_factors.erase(source)


func product() -> float:
	var result := 1.0
	for factor: float in _factors.values():
		result *= factor
	return result


func is_frozen() -> bool:
	return freeze_left > 0.0


func can_freeze() -> bool:
	return not (freeze_immune or freeze_left > 0.0 or immunity_left > 0.0)


func try_freeze() -> bool:
	if freeze_immune or freeze_left > 0.0 or immunity_left > 0.0:
		return false
	freeze_left = FREEZE_TIME
	_factors[FREEZE_SOURCE] = 0.0
	return true


## Ends a running freeze right now (the immunity window starts as if it had run out).
func break_freeze() -> void:
	if freeze_left <= 0.0:
		return
	freeze_left = 0.0
	_factors.erase(FREEZE_SOURCE)
	immunity_left = FREEZE_IMMUNITY
	freeze_ended.emit()


func tick(delta: float) -> void:
	if freeze_left > 0.0:
		freeze_left -= delta
		if freeze_left <= 0.0:
			freeze_left = 0.0
			_factors.erase(FREEZE_SOURCE)
			immunity_left = FREEZE_IMMUNITY
			freeze_ended.emit()
	elif immunity_left > 0.0:
		immunity_left = maxf(0.0, immunity_left - delta)
