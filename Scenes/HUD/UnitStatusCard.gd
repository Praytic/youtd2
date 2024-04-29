extends ButtonStatusCard


@export var _level_panel: ShortResourceStatusPanel


var _unit: Unit = null


#########################
###       Public      ###
#########################

func set_unit(unit: Unit):
	var prev_unit: Unit = _unit
	_unit = unit

	if prev_unit != null && prev_unit.level_up.is_connected(_on_unit_level_up):
		prev_unit.level_up.disconnect(_on_unit_level_up)
	
	if unit != null:
		unit.level_up.connect(_on_unit_level_up)
		_update_level_panel()
		_update_main_button_icon()


func get_unit() -> Unit:
	return _unit


#########################
###      Private      ###
#########################

func _update_main_button_icon():
	var icon_texture: Texture2D
	if _unit is Tower:
		icon_texture = TowerProperties.get_icon(_unit.get_id())
	elif _unit is Creep:
		icon_texture = UnitIcons.get_creep_icon(_unit)

	get_main_button().set_button_icon(icon_texture)


func _update_level_panel():
	var level: int = _unit.get_level()
	_level_panel.set_count(level)
	_level_panel.ack_count()


#########################
###     Callbacks     ###
#########################

func _on_unit_level_up(_level_increased: bool):
	_update_level_panel()
