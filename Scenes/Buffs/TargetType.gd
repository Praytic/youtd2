class_name TargetType

# Filters units by various properties. Leave a property set
# empty if you want to accept any type. For example, if you
# to target all mob types, leave mob_type_list empty.

# TODO: implement UnitType.PLAYER_TOWERS which should apply
# to player towers and not apply to team towers.

enum UnitType {
	TOWERS,
	PLAYER_TOWERS,
	MOBS
}

var _unit_type: int
var _mob_size_list: Array = []
var _mob_type_list: Array = []
var _tower_element_list: Array = []


func _init(unit_type: int):
	_unit_type = unit_type


func set_mob_size_list(mob_size_list: Array):
	_mob_size_list = mob_size_list


func set_mob_type_list(mob_type_list: Array):
	_mob_type_list = mob_type_list


func set_tower_element_list(tower_element_list: Array):
	_tower_element_list = tower_element_list


func match(unit: Unit) -> bool:
	var is_mob = unit is Mob
	var is_tower = unit is Tower

	if is_mob && !_unit_type == UnitType.MOBS:
		return false

	if is_tower && !(_unit_type == UnitType.TOWERS || _unit_type == UnitType.PLAYER_TOWERS):
		return false

	if is_mob:
		var mob_size: int = unit.get_size()
		var mob_type: int = unit.get_type()

		if !_mob_size_list.empty() && !_mob_size_list.has(mob_size):
			return false

		if !_mob_type_list.empty() && !_mob_type_list.has(mob_type):
			return false

	if is_tower:
		var tower_element: int = unit.get_element()

		if !_tower_element_list.empty() && !_tower_element_list.has(tower_element):
			return false

	return true
