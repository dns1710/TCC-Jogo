class_name RainBackdrop
extends Control
## Falling rain streaks drawn as lines, no art. stop_rain() fades them out, which the
## win screen uses to end the storm the opening started.

const DROP_COUNT := 60
const COLOR := Color(0.62, 0.72, 0.9, 0.55)
const SLANT := Vector2(-0.25, 1.0)

var _drops: Array[Dictionary] = []
var _intensity := 1.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in DROP_COUNT:
		_drops.append(_new_drop(true))


func is_raining() -> bool:
	return _intensity > 0.0


## Fades the rain out over `duration` seconds (0 stops it at once).
func stop_rain(duration := 1.5) -> void:
	if _tween:
		_tween.kill()
		_tween = null
	if duration <= 0.0:
		_intensity = 0.0
		queue_redraw()
		return
	_tween = create_tween()
	_tween.tween_property(self, "_intensity", 0.0, duration)


func _process(delta: float) -> void:
	for drop in _drops:
		drop.pos += SLANT * drop.speed * delta
		if drop.pos.y > maxf(size.y, 144.0):
			var fresh := _new_drop(false)
			drop.pos = fresh.pos
			drop.speed = fresh.speed
			drop.length = fresh.length
	queue_redraw()


func _draw() -> void:
	if _intensity <= 0.0:
		return
	var color := COLOR
	color.a *= _intensity
	for i in int(ceil(_drops.size() * _intensity)):
		var drop: Dictionary = _drops[i]
		draw_line(drop.pos, drop.pos + SLANT * drop.length, color, 1.0)


func _new_drop(anywhere: bool) -> Dictionary:
	var width := maxf(size.x, 256.0)
	var height := maxf(size.y, 144.0)
	return {
		"pos": Vector2(randf_range(0.0, width), randf_range(0.0, height) if anywhere else -4.0),
		"speed": randf_range(110.0, 170.0),
		"length": randf_range(4.0, 8.0),
	}
