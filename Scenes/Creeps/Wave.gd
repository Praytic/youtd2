class_name Wave
extends Node


signal wave_ended


enum CsvProperty {
	ID = 0,
	CREEP_SIZE_TYPE = 1,
	CREEP_NUMBER = 2,
	CREEP_CHAMPION_NUMBER = 3,
}

enum State {
	CLEARED,
	DEFEAT,
	SPAWNED,
	SPAWNING,
	PENDING,
}


var _creep_data_list: Array[CreepData]
var _alive_creep_list: Array[Creep] = []
var _id: int : set = set_id, get = get_id
var _wave_number: int : set = set_wave_number, get = get_wave_number
var _race: CreepCategory.enm : set = set_race, get = get_race
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _wave_path: Path2D : set = set_wave_path, get = get_wave_path
#var _modifications: Array[Modification]
var state: int = Wave.State.PENDING
var next_wave: Wave
var _specials: Array[int] = []
var _base_hp: float = 0.0
var _base_armor: float = 0.0

#########################
### Code starts here  ###
#########################


func _ready():
	set_name("Wave")


func _process(_delta):
	# TODO: Add portal lives here
	if _alive_creep_list.is_empty() and state == Wave.State.SPAWNED:
		state = Wave.State.CLEARED
		wave_ended.emit()


#########################
###       Public      ###
#########################


#########################
###      Private      ###
#########################


#########################
###     Callbacks     ###
#########################

func _on_Creep_death(_event: Event, creep: Creep):
	print_verbose("Creep [%s] has died." % creep)
	_alive_creep_list.erase(creep)

func _on_Creep_reached_portal(damage, creep: Creep):
	print_verbose("Creep [%s] reached portal. Damage to portal: %s" % [creep, damage])
	_alive_creep_list.erase(creep)


#########################
### Setters / Getters ###
#########################


func get_csv_property(csv_property: Wave.CsvProperty) -> String:
	return Properties.get_wave_csv_properties_by_id(_id)[csv_property]


func get_creep_size_type() -> String:
	return get_csv_property(CsvProperty.CREEP_SIZE_TYPE)


func get_creep_size_type_num() -> int:
	return CreepSize.from_string(get_creep_size_type())


func get_creep_number() -> int:
	return get_csv_property(CsvProperty.CREEP_NUMBER).to_int()


func get_champion_number() -> int:
	return get_csv_property(CsvProperty.CREEP_CHAMPION_NUMBER).to_int()


# Returns an array of CreepSize enm.that should be spawned
# in the same order as they are stored in this array.
func get_creeps_combination() -> Array:
	var res = []
	var creep_size = get_creep_size_type_num()
	var champ_number = get_champion_number()
	var creep_number = get_creep_number()
	if champ_number == 0:
		for i in range(0, creep_number):
			res.append(creep_size)
	else:
		var champ_rate = int(float(creep_number) / champ_number)
		var champ_size = CreepSize.enm.CHAMPION
		for i in range(0, creep_number):
			res.append(creep_size)
			if i % champ_rate == 0 and i != 0:
				res.append(champ_size)
	return res


# Delay in seconds between each creep spawn
func get_creeps_spawn_delay() -> float:
	# TODO:
	return 1.0


func is_bonus_wave() -> bool:
	# TODO:
	return false


# Path of the creeps to follow toward the portal
func get_wave_path() -> Path2D:
	return _wave_path


func set_wave_path(value: Path2D):
	_wave_path = value


# Returns an array of Modifications that should be
# applied for the specified Creep. This is including
# creep armor, additional HP, and various unique
# effects like 'Regen', 'Mana Shield', 'Wisdom', etc.
func get_modification() -> Array:
	# TODO:
	return []


# Armor type of the creeps
func get_armor_type() -> ArmorType.enm:
	return _armor_type

func set_armor_type(value: ArmorType.enm):
	_armor_type = value


func is_challenge_wave() -> bool:
	return get_wave_number() % 8 == 0


func set_id(value: int):
	_id = value


func get_id() -> int:
	return _id


func set_wave_number(value: int):
	_wave_number = value
	_base_hp = _calculate_base_hp()
	_base_armor = _calculate_base_armor()


func get_wave_number() -> int:
	return _wave_number


func set_race(value: CreepCategory.enm):
	_race = value


func set_specials(specials: Array[int]):
	_specials = specials


func get_specials() -> Array[int]:
	return _specials


func get_race() -> CreepCategory.enm:
	return _race


# Returns an array of possible Creep sizes
# which can be spawned in this wave
func get_creep_sizes() -> Array:
	var result = []
	for creep_size in get_creeps_combination():
		if not result.has(creep_size):
			result.append(creep_size)
	return result


func get_base_hp() -> float:
	return _base_hp


func get_base_armor() -> float:
	return _base_armor


func is_air() -> bool:
	return get_creep_sizes().has(CreepSize.enm.AIR)


func set_creep_data_list(creep_data_list: Array[CreepData]):
	_creep_data_list = creep_data_list


func get_creep_data_list() -> Array[CreepData]:
	return _creep_data_list


func add_alive_creep(creep: Creep):
	_alive_creep_list.append(creep)


# Calculates base HP for a Creep based on 
# the wave number 
func _calculate_base_hp() -> float:
	var a: float
	var b: float
	var c: float
	var d: float
	var e: float
	var f: float
	var g: float

	match Globals.difficulty:
		Difficulty.enm.BEGINNER:
			a = 29 * 1.2
			b = 20 * 1.6
			c = 1.4 * 1.3
			d = 0.015
			e = 0.0001
			f = 0.000007 * 1.9
			g = 0.000000011
		Difficulty.enm.EASY:
			a = 35 * 1.2
			b = 26 * 1.6
			c = 1.6 * 1.3
			d = 0.018
			e = 0.0003
			f = 0.000009 * 1.9
			g = 0.000000012
		Difficulty.enm.MEDIUM:
			a = 42 * 1.2
			b = 33 * 1.6
			c = 1.8 * 1.3
			d = 0.021
			e = 0.0005
			f = 0.000011 * 1.9
			g = 0.000000013
		Difficulty.enm.HARD:
			a = 50 * 1.2
			b = 41 * 1.6
			c = 2.0 * 1.3
			d = 0.024
			e = 0.0008
			f = 0.000013 * 1.9
			g = 0.000000015
		Difficulty.enm.EXTREME:
			a = 59 * 1.2
			b = 50 * 1.6
			c = 2.2 * 1.3
			d = 0.027
			e = 0.001
			f = 0.000015 * 1.9
			g = 0.000000018

	var j: int = get_wave_number() - 1
	var health: float = a + j * (b + j * (c + j * (d + j * (e + j * (f + j * g)))))

	return health


func _calculate_base_armor() -> float:
	var a: float
	var b: float
	var c: float

	match Globals.difficulty:
		Difficulty.enm.BEGINNER:
			a = 0
			b = 0.26
			c = 0
		Difficulty.enm.EASY:
			a = 2
			b = 0.28
			c = 0
		Difficulty.enm.MEDIUM:
			a = 4
			b = 0.3
			c = 0
		Difficulty.enm.HARD:
			a = 6
			b = 0.32
			c = 0.004
		Difficulty.enm.EXTREME:
			a = 8
			b = 0.34
			c = 0.001

	var j: int = get_wave_number() - 1
	var base_armor: int = a + j * (b + j * c)

	print("%d = %f" % [get_wave_number(), base_armor])

	return base_armor
