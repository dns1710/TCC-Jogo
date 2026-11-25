class_name DDAConversion
extends RefCounted
## One room change the difficulty adjustment wants: turn a room of one type into another.

var from_type: Room.Type
var to_type: Room.Type
## True when this conversion uses up the once-per-act shop swap flag.
var uses_shop_flag := false
## True when this conversion uses up the once-per-act hoarded-gold shop swap.
var uses_hoard_flag := false
## True when this conversion uses up the once-per-run emergency campfire.
var uses_emergency_flag := false


static func make(p_from: Room.Type, p_to: Room.Type, p_uses_shop_flag := false) -> DDAConversion:
	var conversion := DDAConversion.new()
	conversion.from_type = p_from
	conversion.to_type = p_to
	conversion.uses_shop_flag = p_uses_shop_flag
	return conversion


func _to_string() -> String:
	var mark := "*" if uses_shop_flag else ""
	mark += "$" if uses_hoard_flag else ""
	mark += "!" if uses_emergency_flag else ""
	return "%s->%s%s" % [Room.Type.keys()[from_type], Room.Type.keys()[to_type], mark]
