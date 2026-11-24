class_name FreezeStatus
extends Status
## Stops the owner's turn bar for ATBModifiers.FREEZE_TIME, then the owner is
## immune to Freeze for FREEZE_IMMUNITY. A refused freeze (immune, already
## frozen, boss) removes this status immediately and has no other effect.

func initialize_status(target: Node) -> void:
	var mods: ATBModifiers = target.atb_mods
	if not mods.try_freeze():
		_end()
		return
	mods.freeze_ended.connect(_end, CONNECT_ONE_SHOT)


func get_tooltip() -> String:
	return "Turn bar stopped for %.1f seconds, then immune to Freeze for %d seconds." % [
		ATBModifiers.FREEZE_TIME, int(ATBModifiers.FREEZE_IMMUNITY)
	]


func _end() -> void:
	can_expire = true
	duration = 0
