extends GutTest


func test_reroll_first_room():
	var map := Map.new()

	var room := Room.new()
	room.row = 0
	room.type = Room.Type.MONSTER

	map._reroll_room(room)

	assert_eq(room.type, Room.Type.MONSTER)

	map.free()
