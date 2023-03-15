class_name TargetType

# Filters units by various properties. Leave a property set
# empty if you want to accept any type. For example, if you
# to target all creep types, leave creep_category_list empty.

# TODO: implement UnitType.PLAYER_TOWERS which should apply
# to player towers and not apply to team towers.

enum UnitType {
	TOWERS,
	PLAYER_TOWERS,
	CREEPS
}

var _unit_type: int
var _creep_size_list: Array = []
var _creep_category_list: Array = []
var _tower_element_list: Array = []


func _init(unit_type: int):
	_unit_type = unit_type


func set_creep_size_list(creep_size_list: Array):
	_creep_size_list = creep_size_list


func set_creep_category_list(creep_category_list: Array):
	_creep_category_list = creep_category_list


func set_tower_element_list(tower_element_list: Array):
	_tower_element_list = tower_element_list


func match(unit: Unit) -> bool:
	var is_creep = unit.is_creep()
	var is_tower = unit.is_tower()

	if is_creep && !_unit_type == UnitType.CREEPS:
		return false

	if is_tower && !(_unit_type == UnitType.TOWERS || _unit_type == UnitType.PLAYER_TOWERS):
		return false

	if is_creep:
		var creep_size: int = unit.get_size()
		var creep_category: int = unit.get_category()

		if !_creep_size_list.is_empty() && !_creep_size_list.has(creep_size):
			return false

		if !_creep_category_list.is_empty() && !_creep_category_list.has(creep_category):
			return false

	if is_tower:
		var tower_element: int = unit.get_element()

		if !_tower_element_list.is_empty() && !_tower_element_list.has(tower_element):
			return false

	return true
