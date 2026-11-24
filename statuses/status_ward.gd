class_name WardStatus
extends Status
## Negates the next debuff applied to its owner, then ends. The interception lives in
## StatusHandler.add_status; this status only carries the data and the tooltip.


func get_tooltip() -> String:
	return "The next debuff applied is negated, then Ward ends."
