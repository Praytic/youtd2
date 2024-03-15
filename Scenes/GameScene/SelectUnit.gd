class_name SelectUnit extends Node

# Implements logic for hovering and selecting units. Needed
# because only one unit may be hovered or selected at a
# time.

signal selected_unit_changed(prev_unit: Unit)


var _units_under_mouse_list: Array[Unit] = []
var _hovered_unit: Unit = null
var _selected_unit: Unit = null


#########################
###     Built-in      ###
#########################

func _ready():
	EventBus.mouse_entered_unit.connect(_on_mouse_entered_unit)
	EventBus.mouse_exited_unit.connect(_on_mouse_exited_unit)


#########################
###       Public      ###
#########################

func set_selected_unit(new_selected_unit: Unit):
	var old_selected_unit: Unit = _selected_unit

	if old_selected_unit != null:
		old_selected_unit.set_selected(false)

	if new_selected_unit != null:
		new_selected_unit.set_selected(true)

		if !new_selected_unit.tree_exited.is_connected(_on_unit_tree_exited):
			new_selected_unit.tree_exited.connect(_on_unit_tree_exited.bind(new_selected_unit))

	_selected_unit = new_selected_unit
	selected_unit_changed.emit(old_selected_unit)


func get_selected_unit() -> Unit:
	return _selected_unit


func get_hovered_unit() -> Unit:
	return _hovered_unit


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


#########################
###     Callbacks     ###
#########################

func _on_mouse_entered_unit(unit: Unit):
	_units_under_mouse_list.append(unit)
	if !unit.tree_exited.is_connected(_on_unit_tree_exited):
		unit.tree_exited.connect(_on_unit_tree_exited.bind(unit))
	update_hovered_unit()


func _on_mouse_exited_unit(unit: Unit):
	_units_under_mouse_list.erase(unit)
	update_hovered_unit()


# NOTE: Need this slot because "mouse_exited" signal doesn't
# get emitted when units exit the tree because of
# queue_free().
func _on_unit_tree_exited(unit: Unit):
	var selected_unit_is_being_removed: bool = _selected_unit == unit
	if selected_unit_is_being_removed:
		set_selected_unit(null)

	if _units_under_mouse_list.has(unit):
		_units_under_mouse_list.erase(unit)
		update_hovered_unit()
