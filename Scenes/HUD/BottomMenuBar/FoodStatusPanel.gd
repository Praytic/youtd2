extends ResourceStatusPanel


func _ready():
	super()

	FoodManager.changed.connect(on_food_changed)

	on_food_changed()


func on_food_changed():
	var current_food: int = FoodManager.get_current_food()
	var food_cap: int = FoodManager.get_food_cap()
	var label_text: String = "%d/%d" % [current_food, food_cap]
	set_label_text(label_text)
