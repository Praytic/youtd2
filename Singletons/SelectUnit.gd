extends Node

# Singleton that implements logic for hovering and selecting
# over units. Needed because only one unit may be hovered or
# selected at a time.

signal selected_unit_changed()


var _units_under_mouse_list: Array[Unit] = []
var _hovered_unit: Unit = null
var _selected_unit: Unit = null


func get_selected_unit() -> Unit:
	return _selected_unit


func on_unit_mouse_entered(unit: Unit):
	_units_under_mouse_list.append(unit)
	update_hovered_unit()


func on_unit_mouse_exited(unit: Unit):
	_units_under_mouse_list.erase(unit)
	update_hovered_unit()


func update_hovered_unit():
	var old_hovered_unit: Unit = _hovered_unit

	if old_hovered_unit != null:
		old_hovered_unit.set_hovered(false)
		_hovered_unit = null

#	NOTE: sort list by y position so that if units overlap,
#	the one in isometric front (higher y) gets picked
	_units_under_mouse_list.sort_custom(func(a, b): return a.get_visual_position().y > b.get_visual_position().y)

	if _units_under_mouse_list.size() > 0:
		var new_hovered_unit = _units_under_mouse_list[0]
		new_hovered_unit.set_hovered(true)
		_hovered_unit = new_hovered_unit


func _unhandled_input(event):
	var cancel_pressed: bool = event.is_action_pressed("ui_cancel")

	if cancel_pressed:
		_selected_unit.set_selected(false)
		_selected_unit = null
		selected_unit_changed.emit()

		return

	var left_click: bool = event.is_action_pressed("left_click")

	if !left_click:
		return

# 	NOTE: this handles both switching to new unit and
# 	deselecting by clicking on nothing
	var old_selected_unit: Unit = _selected_unit
	if old_selected_unit != null:
		old_selected_unit.set_selected(false)

	var new_selected_unit: Unit = _hovered_unit
	if new_selected_unit != null:
		new_selected_unit.set_selected(true)

	_selected_unit = new_selected_unit
	selected_unit_changed.emit()
