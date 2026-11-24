extends Node
## Test helper: counts process frames, so a test can tell whether the tree is paused.

var ticks := 0


func _process(_delta: float) -> void:
	ticks += 1
