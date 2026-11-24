class_name DamageEffect
extends Effect

var amount := 0
var receiver_modifier_type := Modifier.Type.DMG_TAKEN
var source: Node = null
## Sides of the die the hit was rolled with (0 for flat hits). Brittle adds one more die of this size.
var die_sides := 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			target.take_damage(amount, receiver_modifier_type, source, die_sides)
			SFXPlayer.play(sound)
