class_name GoldenClover
extends Relic

@export var min_extra_gold := 8
@export var max_extra_gold := 13

func activate_relic(owner: RelicUI) -> void:
	var relic_handler := owner.get_parent().get_parent().get_parent() as RelicHandler

	if relic_handler and relic_handler.run_stats:
		relic_handler.run_stats.gold += randi_range(min_extra_gold, max_extra_gold)
		owner.flash()
