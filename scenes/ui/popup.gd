extends Label

func setup(poptext: String, color: Color = Color.WHITE) -> void:
	text = str(poptext)
	modulate = color

	var start_pos = position

	scale = Vector2.ONE * 0.5

	var tween = create_tween()

	tween.parallel().tween_property(self, "position", start_pos + Vector2(randf_range(-20,20), -50), 0.8)

	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)

	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)

	tween.finished.connect(queue_free)
