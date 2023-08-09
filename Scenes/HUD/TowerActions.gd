extends Control

# Container for active (autocast) tower specials

@export var _autocasts_container: VBoxContainer


var _tower: Tower : set = set_tower


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	_on_selected_unit_changed()


func _update_autocasts(tower: Tower):
	_clear_autocasts()

	var autocast_list: Array[Autocast] = tower.get_autocast_list()

	for autocast in autocast_list:
		var autocast_button: AutocastButton = Globals.autocast_button_scene.instantiate()
		autocast_button.set_autocast(autocast)
		_autocasts_container.add_child(autocast_button)


func _clear_autocasts():
	for button in _autocasts_container.get_children():
		button.queue_free()

func _on_selected_unit_changed(_prev_unit = null):
	var selected_unit: Unit = SelectUnit.get_selected_unit()
	
	visible = selected_unit != null && selected_unit is Tower

	if selected_unit is Tower and selected_unit == _tower:
		var tower: Tower = selected_unit as Tower
		_update_autocasts(tower)
	else:
		_clear_autocasts()


func set_tower(value: Tower):
	_tower = value
