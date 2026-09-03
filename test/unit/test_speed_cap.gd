extends GutTest


func test_speed_cap():
	var stats := Stats.new()

	stats.max_speed = 10
	stats.speed = 30

	assert_eq(stats.speed, 20)
