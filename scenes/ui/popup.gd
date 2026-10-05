extends Label

func setup(poptext: String, color: Color = Color.WHITE) -> void:
	text = str(poptext)
	modulate = color
	
	reset_size()
	pivot_offset = size / 2.0
	global_position -= size/2.0
	
	var start_pos = global_position
	var peak_pos = start_pos + Vector2(0,-40)
	modulate.a = 0.0
	
	scale = Vector2.ONE * 0.5

	var tween = create_tween()
	
	#up
	tween.tween_property(self, "global_position", peak_pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	#fade in
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)
	
	#scale
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)
	
	#down
	tween.tween_property(self, "global_position", start_pos + Vector2(0,-10), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	#fade out
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	
	tween.finished.connect(queue_free)
	
	#tween.parallel().tween_property(self, "position", start_pos + Vector2(randf_range(-20,20), -50), 0.8)
	
	#tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.15)

	#tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
