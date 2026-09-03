extends GutTest


func test_map_reroll_boss_room():
	var map := Map.new()

	var boss_room := Room.new()
	boss_room.row = MapGenerator.FLOORS - 1
	boss_room.type = Room.Type.BOSS

	map._reroll_room(boss_room)

	assert_eq(boss_room.type, Room.Type.BOSS)

	map.free()
