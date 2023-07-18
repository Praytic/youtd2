extends ResourceStatusPanel


func _ready():
	super()

	GoldControl.gold_change.connect(_on_gold_change)

	var initial_value: int = int(GoldControl.get_gold())
	_on_gold_change(initial_value)


func _on_gold_change(new_value):
	set_label_text(str(int(new_value)))
	
# test 
