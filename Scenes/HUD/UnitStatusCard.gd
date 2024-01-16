extends ButtonStatusCard


@export var _level_panel: ShortResourceStatusPanel


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)


func _on_selected_unit_changed(prev_unit):
	var selected_unit = SelectUnit.get_selected_unit()
	
	if selected_unit != null:
		visible = true
		get_main_button().set_pressed(true)
		if !selected_unit.level_changed.is_connected(_update_level_panel):
			selected_unit.level_changed.connect(_update_level_panel)
		if prev_unit != null && prev_unit.level_changed.is_connected(_update_level_panel):
			prev_unit.level_changed.disconnect(_update_level_panel)
		
		_update_level_panel()
		_update_main_button_icon()
	else:
		visible = false
		get_main_button().set_pressed(false)


func _update_main_button_icon():
	var selected_unit = SelectUnit.get_selected_unit()
	
	if selected_unit != null:
		var icon_texture
		if selected_unit is Tower:
			icon_texture = TowerProperties.get_icon_texture(selected_unit.get_id())
		elif selected_unit is Creep:
			icon_texture = CreepProperties.get_icon_texture(selected_unit)
		get_main_button().set_button_icon(icon_texture)


func _update_level_panel():
	var selected_unit = SelectUnit.get_selected_unit()
	if selected_unit != null:
		_level_panel.set_count(selected_unit.get_level())
		_level_panel.ack_count()
