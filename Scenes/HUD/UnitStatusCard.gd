extends ButtonStatusCard


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)


func _process(_delta):
	visible = SelectUnit.get_selected_unit() != null


func _on_selected_unit_changed(prev_unit):
	if prev_unit == null:
		get_main_button().set_pressed(true)
