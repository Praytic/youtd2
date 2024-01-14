extends ButtonStatusCard


@export var _level_panel: ShortResourceStatusPanel


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)


func _process(_delta):
	visible = SelectUnit.get_selected_unit() != null


func _on_selected_unit_changed(prev_unit):
	var selected_unit = SelectUnit.get_selected_unit()
	
	if selected_unit != null:
		selected_unit.level_changed.connect(_update_level_panel)
		if prev_unit == null:
			get_main_button().set_pressed(true)
	
	_update_level_panel()
	_update_main_button_icon()


func _update_main_button_icon():
	var selected_unit = SelectUnit.get_selected_unit()
	
	if selected_unit != null:
		var icon_texture
		if selected_unit is Tower:
			icon_texture = TowerProperties.get_icon_texture(selected_unit.get_id())
		elif selected_unit is Creep:
			icon_texture = CreepProperties.get_icon_texture(selected_unit.get_id())
		get_main_button().set_button_icon(icon_texture)


func _update_level_panel():
	var selected_unit = SelectUnit.get_selected_unit()
	if selected_unit != null:
		_level_panel.set_count(selected_unit.get_level())
		_level_panel.ack_count()
