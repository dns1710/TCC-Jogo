class_name BlockEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			#target.heal(amount)
			target.stats.block += floori(amount * target.block_gain_multiplier)
			SFXPlayer.play(sound)
