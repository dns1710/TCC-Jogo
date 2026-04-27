class_name ShopCard
extends VBoxContainer


@onready var card_container: CenterContainer = %CardContainer
@onready var price: HBoxContainer = %Price
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton
@onready var gold_cost := RNG.instance.randi_range(100, 300)



func update(run_stats: RunStats) -> void:
	if not card_container or not price or not buy_button:
		return

	price_label.text = str(gold_cost)
	
	if run_stats.gold >= gold_cost:
		price_label.remove_theme_color_override("font_color")
		buy_button.disabled = false
	else:
		price_label.add_theme_color_override("font_color", Color.RED)
		buy_button.disabled = true

func _on_buy_button_pressed() -> void:
	card_container.queue_free()
	price.queue_free()
	buy_button.queue_free()
