class_name Dice
extends Node

static func roll(amount: int, max_value: int, bonus: int = 0) -> int:
	var total := 0
	
	for i in amount:
		total += randi_range(1,max_value)
	
	total += bonus
	
	#print(amount, "d", max_value, "+", bonus, " = ", total)
	
	return total
