extends ResourceStatusPanel


func _ready():
	super()

	GoldControl.gold_change.connect(_on_gold_change)
	_on_gold_change()


func _on_gold_change():
	var new_value: float = GoldControl.get_gold()
	set_label_text(str(int(new_value)))
