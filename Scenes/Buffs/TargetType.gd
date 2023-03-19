class_name TargetType

# Filters units by various properties. Create a TargetType
# like this:
# 
# TargetType.new(TargetType.CREEPS + TargetType.RACE_UNDEAD)


# TODO: implement UnitType.PLAYER_TOWERS which should apply
# to player towers and not apply to team towers.

const CREEPS: int 			= 0x1
const TOWERS: int 			= 0x2
const PLAYER_TOWERS: int 	= 0x4

const RACE_UNDEAD: int 		= 0x8
const RACE_MAGIC: int 		= 0x10
const RACE_NATURE: int 		= 0x20
const RACE_ORC: int 		= 0x40
const RACE_HUMANOID: int 	= 0x80

const SIZE_MASS: int 		= 0x100
const SIZE_NORMAL: int 		= 0x200
const SIZE_CHAMPION: int 	= 0x400
const SIZE_BOSS: int 		= 0x800
const SIZE_AIR: int 		= 0x1000

const ELEMENT_ASTRAL: int 	= 0x2000
const ELEMENT_DARKNESS: int = 0x4000
const ELEMENT_NATURE: int 	= 0x8000
const ELEMENT_FIRE: int 	= 0x10000
const ELEMENT_ICE: int 		= 0x20000
const ELEMENT_STORM: int 	= 0x40000
const ELEMENT_IRON: int 	= 0x80000

enum UnitType {
	TOWERS,
	PLAYER_TOWERS,
	CREEPS
}

var _unit_type: int
var _creep_size_list: Array = []
var _creep_category_list: Array = []
var _tower_element_list: Array = []


func _init(bitmask: int):
	_unit_type = TargetType._get_unit_type(bitmask)
	_creep_size_list = TargetType._get_creep_size_list(bitmask)
	_creep_category_list = TargetType._get_creep_category_list(bitmask)
	_tower_element_list = TargetType._get_tower_element_list(bitmask)


func match(unit: Unit) -> bool:
	var is_creep = unit.is_creep()
	var is_tower = unit.is_tower()

	match _unit_type:
		UnitType.CREEPS:
			if !is_creep:
				return false
		UnitType.TOWERS:
			if !is_tower:
				return false
		UnitType.PLAYER_TOWERS:
			if !is_tower:
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


static func _get_unit_type(bitmask: int) -> UnitType:
	var creeps_set: bool = Utils.bit_is_set(bitmask, CREEPS)
	var towers_set: bool = Utils.bit_is_set(bitmask, TOWERS)
	var player_towers_set: bool = Utils.bit_is_set(bitmask, PLAYER_TOWERS)

	if creeps_set:
		return UnitType.CREEPS
	elif towers_set:
		return UnitType.TOWERS
	elif player_towers_set:
		return UnitType.PLAYER_TOWERS
	else:
		return UnitType.CREEPS


static func _get_creep_size_list(bitmask: int) -> Array[Creep.Size]:
	var bit_to_size_map: Dictionary = {
		SIZE_MASS: Creep.Size.MASS,
		SIZE_NORMAL: Creep.Size.NORMAL,
		SIZE_CHAMPION: Creep.Size.CHAMPION,
		SIZE_BOSS: Creep.Size.BOSS,
		SIZE_AIR: Creep.Size.AIR,
	}

	var list: Array[Creep.Size] = []

	for bit in bit_to_size_map.keys():
		var element: Creep.Size = bit_to_size_map[bit]
		var is_set: bool = Utils.bit_is_set(bitmask, bit)

		if is_set:
			list.append(element)

	return list


static func _get_creep_category_list(bitmask: int) -> Array[Creep.Category]:
	var bit_to_category_map: Dictionary = {
		RACE_UNDEAD: Creep.Category.UNDEAD,
		RACE_MAGIC: Creep.Category.MAGIC,
		RACE_NATURE: Creep.Category.NATURE,
		RACE_ORC: Creep.Category.ORC,
		RACE_HUMANOID: Creep.Category.HUMANOID,
	}

	var list: Array[Creep.Category] = []

	for bit in bit_to_category_map.keys():
		var category: Creep.Category = bit_to_category_map[bit]
		var is_set: bool = Utils.bit_is_set(bitmask, bit)

		if is_set:
			list.append(category)

	return list


static func _get_tower_element_list(bitmask: int) -> Array[Tower.Element]:
	var bit_to_element_map: Dictionary = {
		ELEMENT_ASTRAL: Tower.Element.ASTRAL,
		ELEMENT_DARKNESS: Tower.Element.DARKNESS,
		ELEMENT_NATURE: Tower.Element.NATURE,
		ELEMENT_FIRE: Tower.Element.FIRE,
		ELEMENT_ICE: Tower.Element.ICE,
		ELEMENT_STORM: Tower.Element.STORM,
		ELEMENT_IRON: Tower.Element.IRON,
	}

	var list: Array[Tower.Element] = []

	for bit in bit_to_element_map.keys():
		var element: Tower.Element = bit_to_element_map[bit]
		var is_set: bool = Utils.bit_is_set(bitmask, bit)

		if is_set:
			list.append(element)

	return list
