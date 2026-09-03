extends GutTest


func test_negative_hp():
	var stats := Stats.new()
	stats.max_health = 30
	stats.health = 30

	stats.take_damage(50)

	assert_eq(stats.health, 0)
