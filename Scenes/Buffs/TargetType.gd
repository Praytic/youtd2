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
const CORPSES: int 			= 0x100000

const RACE_UNDEAD: int 		= 0x8
const RACE_MAGIC: int 		= 0x10
const RACE_NATURE: int 		= 0x20
const RACE_ORC: int 		= 0x40
const RACE_HUMANOID: int 	= 0x80
const RACE_CHALLENGE: int 	= 0x200000
const RACE_ALL: int 		= RACE_UNDEAD | RACE_MAGIC | RACE_NATURE | RACE_ORC | RACE_HUMANOID | RACE_CHALLENGE

const SIZE_MASS: int 		= 0x100
const SIZE_NORMAL: int 		= 0x200
const SIZE_CHAMPION: int 	= 0x400
const SIZE_BOSS: int 		= 0x800
const SIZE_AIR: int 		= 0x1000
const SIZE_ALL: int 		= SIZE_MASS | SIZE_NORMAL | SIZE_CHAMPION | SIZE_BOSS | SIZE_AIR

const ELEMENT_ASTRAL: int 	= 0x2000
const ELEMENT_DARKNESS: int = 0x4000
const ELEMENT_NATURE: int 	= 0x8000
const ELEMENT_FIRE: int 	= 0x10000
const ELEMENT_ICE: int 		= 0x20000
const ELEMENT_STORM: int 	= 0x40000
const ELEMENT_IRON: int 	= 0x80000
const ELEMENT_ALL: int 		= ELEMENT_ASTRAL | ELEMENT_DARKNESS | ELEMENT_NATURE | ELEMENT_FIRE | ELEMENT_ICE | ELEMENT_STORM | ELEMENT_IRON


static var _tower_element_to_bit: Dictionary = {
	Element.enm.ASTRAL: TargetType.ELEMENT_ASTRAL,
	Element.enm.DARKNESS: TargetType.ELEMENT_DARKNESS,
	Element.enm.NATURE: TargetType.ELEMENT_NATURE,
	Element.enm.FIRE: TargetType.ELEMENT_FIRE,
	Element.enm.ICE: TargetType.ELEMENT_ICE,
	Element.enm.STORM: TargetType.ELEMENT_STORM,
	Element.enm.IRON: TargetType.ELEMENT_IRON,
}

static var _creep_category_to_bit: Dictionary = {
	CreepCategory.enm.UNDEAD: RACE_UNDEAD,
	CreepCategory.enm.MAGIC: RACE_MAGIC,
	CreepCategory.enm.NATURE: RACE_NATURE,
	CreepCategory.enm.ORC: RACE_ORC,
	CreepCategory.enm.HUMANOID: RACE_HUMANOID,
	CreepCategory.enm.CHALLENGE: RACE_CHALLENGE,
}

static var _creep_size_to_bit: Dictionary = {
	CreepSize.enm.MASS: SIZE_MASS,
	CreepSize.enm.NORMAL: SIZE_NORMAL,
	CreepSize.enm.CHAMPION: SIZE_CHAMPION,
	CreepSize.enm.BOSS: SIZE_BOSS,
	CreepSize.enm.AIR: SIZE_AIR,
	CreepSize.enm.CHALLENGE_BOSS: SIZE_BOSS,
	CreepSize.enm.CHALLENGE_MASS: SIZE_MASS,
}

enum UnitType {
	TOWERS,
	PLAYER_TOWERS,
	CREEPS,
	CORPSES
}

var _unit_type: UnitType
var _bitmask: int = 0


#########################
###     Built-in      ###
#########################

func _init(bitmask: int):
	_bitmask = bitmask
	_unit_type = TargetType._get_unit_type(bitmask)

	var group_bitmask_list: Array[int] = [
		ELEMENT_ALL,
		RACE_ALL,
		SIZE_ALL,
	]
	
#	NOTE: if target type was created with no bit specified
#	for group (element, race or size) then it is assumed
#	that we should accept all variations for that group.
#	Therefore we set all bits from those group bitmasks.
	for all_bitmask in group_bitmask_list:
		var no_filter_for_section: bool = _bitmask & all_bitmask == 0
		if no_filter_for_section:
			_bitmask |= all_bitmask

#	NOTE: treat PLAYER_TOWERS as TOWERS and vice versa. Will
#	figure out how to deal with it properly later.
	if _bitmask & PLAYER_TOWERS == PLAYER_TOWERS:
		_bitmask |= TOWERS
	if _bitmask & TOWERS == TOWERS:
		_bitmask |= PLAYER_TOWERS


#########################
###       Public      ###
#########################

# NOTE: need to use bitmask to get optimal performance.
# TargetType.match() will get called very frequently via
# Utils.get_units_in_range().
func match(unit: Unit) -> bool:
	var is_match: bool = _bitmask & unit.get_target_bitmask() == unit.get_target_bitmask()

	return is_match


#########################
###       Static      ###
#########################

static func _get_unit_type(bitmask: int) -> UnitType:
	var creeps_set: bool = Utils.bit_is_set(bitmask, CREEPS)
	var towers_set: bool = Utils.bit_is_set(bitmask, TOWERS)
	var player_towers_set: bool = Utils.bit_is_set(bitmask, PLAYER_TOWERS)
	var corpses_set: bool = Utils.bit_is_set(bitmask, CORPSES)

	if creeps_set:
		return UnitType.CREEPS
	elif towers_set:
		return UnitType.TOWERS
	elif player_towers_set:
		return UnitType.PLAYER_TOWERS
	elif corpses_set:
		return UnitType.CORPSES
	else:
		return UnitType.CREEPS


static func make_unit_bitmask(unit: Unit) -> int:
	var bitmask: int = 0

	if unit is Tower:
		var tower: Tower = unit as Tower

		var element: Element.enm = tower.get_element()
		var element_bit: int = _tower_element_to_bit[element]
		
		bitmask |= TargetType.TOWERS
		bitmask |= TargetType.PLAYER_TOWERS
		bitmask |= element_bit
	elif unit is Creep:
		var creep: Creep = unit as Creep

		var category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
		var category_bit: int = _creep_category_to_bit[category]
		var size: CreepSize.enm = creep.get_size()
		var size_bit: int = _creep_size_to_bit[size]

		bitmask |= TargetType.CREEPS
		bitmask |= category_bit
		bitmask |= size_bit
	elif unit is CreepCorpse:
		bitmask |= TargetType.CORPSES

	return bitmask
