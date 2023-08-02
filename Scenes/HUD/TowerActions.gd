extends Control

# Container for active tower specials

@export var _autocasts_container: VBoxContainer
@export var _autocast_button_placeholder: Button


var _selling_for_real: bool = false


func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)
	_on_selected_unit_changed()
	_autocast_button_placeholder.queue_free()


func _update_autocasts(tower: Tower):
	for button in _autocasts_container.get_children():
		button.queue_free()

	var autocast_list: Array[Autocast] = tower.get_autocast_list()

	for autocast in autocast_list:
		var autocast_button: AutocastButton = Globals.autocast_button_scene.instantiate()
		autocast_button.set_autocast(autocast)
		_autocasts_container.add_child(autocast_button)


func _on_selected_unit_changed():
	var selected_unit: Unit = SelectUnit.get_selected_unit()
	
	visible = selected_unit != null && selected_unit is Tower

	if selected_unit is Tower:
		position = selected_unit.position
		var tower: Tower = selected_unit as Tower
		_update_autocasts(tower)
