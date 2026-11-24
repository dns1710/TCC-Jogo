class_name EventRoomPool
extends Resource

@export var events: Array[EventDefinition]


## Picks an event not in `seen` (resource paths). When every event has been
## seen, repeats are allowed and a warning is logged.
func pick(seen: Array[String]) -> EventDefinition:
	if events.is_empty():
		return null

	var unseen: Array[EventDefinition] = []
	for event in events:
		if not seen.has(event.resource_path):
			unseen.append(event)

	if unseen.is_empty():
		push_warning("Event pool exhausted; repeating an event.")
		unseen = events

	return RNG.array_pick_random(unseen)
