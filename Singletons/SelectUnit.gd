extends Node

# Singleton that implements logic for hovering and selecting
# over units. Needed because only one unit may be hovered or
# selected at a time.

signal selected_unit_changed(prev_unit: Unit)


var _units_under_mouse_list: Array[Unit] = []
var _hovered_unit: Unit = null
var _selected_unit: Unit = null


# Connect a unit to the selection system. Selection area
# will be used to detect when the mouse is over the unit.
func connect_unit(unit: Unit, selection_area: Area2D):
	selection_area.mouse_entered.connect(on_unit_mouse_entered.bind(unit))
	selection_area.mouse_exited.connect(on_unit_mouse_exited.bind(unit))


func set_selected_unit(new_selected_unit: Unit):
	var old_selected_unit: Unit = _selected_unit

	if old_selected_unit != null:
		old_selected_unit.set_selected(false)

	if new_selected_unit != null:
		new_selected_unit.set_selected(true)

		if !new_selected_unit.tree_exited.is_connected(on_unit_tree_exited):
			new_selected_unit.tree_exited.connect(on_unit_tree_exited.bind(new_selected_unit))

	_selected_unit = new_selected_unit
	selected_unit_changed.emit(old_selected_unit)


func get_selected_unit() -> Unit:
	return _selected_unit


func get_hovered_unit() -> Unit:
	return _hovered_unit


func on_unit_mouse_entered(unit: Unit):
	_units_under_mouse_list.append(unit)
	if !unit.tree_exited.is_connected(on_unit_tree_exited):
		unit.tree_exited.connect(on_unit_tree_exited.bind(unit))
	update_hovered_unit()


func on_unit_mouse_exited(unit: Unit):
	_units_under_mouse_list.erase(unit)
	update_hovered_unit()


# NOTE: Need this slot because "mouse_exited" signal doesn't
# get emitted when units exit the tree because of
# queue_free().
func on_unit_tree_exited(unit: Unit):
	var selected_unit_is_being_removed: bool = _selected_unit == unit
	if selected_unit_is_being_removed:
		set_selected_unit(null)

	if _units_under_mouse_list.has(unit):
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
# 	NOTE: Can't select when mouse is busy with some other
# 	action, for example moving items.
	var can_select: bool = MouseState.get_state() == MouseState.enm.NONE
	if !can_select:
		return

	var cancel_pressed: bool = event.is_action_released("ui_cancel")

	if cancel_pressed && _selected_unit != null:
		set_selected_unit(null)

		return

	var left_click: bool = event.is_action_released("left_click")

	if left_click:
		set_selected_unit(_hovered_unit)
