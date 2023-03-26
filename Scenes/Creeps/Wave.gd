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


# Array[Creep] stores scenes of live in-game creeps
var _creeps: Array
var _id: int : set = set_id, get = get_id
var _wave_number: int : set = set_wave_number, get = get_wave_number
var _race: Creep.Category : set = set_race, get = get_race
var _armor_type: ArmorType.enm : set = set_armor_type, get = get_armor_type
var _wave_path: Path2D : set = set_wave_path, get = get_wave_path
# Array[Modification]
var _modifications: Array
var state: int = Wave.State.PENDING
var next_wave: Wave

#########################
### Code starts here  ###
#########################


func _ready():
	pass # Replace with function body.


func _process(delta):
	# TODO: Add portal lives here
	if _creeps.is_empty() and state != Wave.State.CLEARED:
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

func _on_Creep_death(creep: Creep):
	_creeps.erase(creep)


#########################
### Setters / Getters ###
#########################


func get_csv_property(csv_property: Wave.CsvProperty) -> String:
	return Properties.get_wave_csv_properties_by_id(_id)[csv_property]


func get_creep_size_type() -> String:
	return get_csv_property(CsvProperty.CREEP_SIZE_TYPE)


func get_creep_size_type_num() -> int:
	return Creep.Size.get(get_creep_size_type().to_upper())


func get_creep_number() -> int:
	return get_csv_property(CsvProperty.CREEP_NUMBER).to_int()


func get_champion_number() -> int:
	return get_csv_property(CsvProperty.CREEP_CHAMPION_NUMBER).to_int()


# Returns an array of Creep.Size that should be spawned
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
		var champ_rate = creep_number / champ_number
		var champ_size = Creep.Size.CHAMPION
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


func get_wave_number() -> int:
	return _wave_number


func set_race(value: int):
	_race = value


func get_race() -> int:
	return _race


# Returns an array of possible Creep sizes
# which can be spawned in this wave
func get_creep_sizes() -> Array:
	var result = []
	for creep_size in get_creeps_combination():
		if not result.has(creep_size):
			result.append(creep_size)
	return result


# Calculates base HP for a Creep based on 
# the wave number 
func get_base_hp() -> float:
	#TODO: Formula
	return get_wave_number() * 100


func is_air() -> bool:
	return get_creep_sizes().has(Creep.Size.AIR)
