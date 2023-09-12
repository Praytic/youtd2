@tool
extends ResourceStatusPanel


func _ready():
	super()
	
	if not Engine.is_editor_hint():
		GoldControl.changed.connect(_on_gold_changed)
		_on_gold_changed()


func _on_gold_changed():
	var new_value: float = GoldControl.get_gold()
	set_label_text(str(int(new_value)))
