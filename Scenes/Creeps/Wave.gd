class_name Wave
extends Node


signal wave_ended(cause)


enum CsvProperty {
	ID = 0,
	CREEP_SIZE_TYPE = 1,
	CREEP_NUMBER = 2,
	CREEP_CHAMPION_NUMBER = 3,
}

enum EndCause {
	CLEARED,
	DEFEAT
}


@onready var wave_paths = get_tree().get_nodes_in_group("wave_path")


var _id: int
var _wave_number: int
var _creeps: Array


#########################
### Code starts here  ###
#########################

func _init(id: int, wave_number: int):
	_id = id
	_wave_number = wave_number
	for creep_size in get_creeps_combination():
		var creep = Creep.new()
		_creeps.append(creep)


func _ready():
	pass # Replace with function body.


func _process(delta):
	pass


#########################
###       Public      ###
#########################


#########################
###      Private      ###
#########################


#########################
### Setters / Getters ###
#########################

func get_csv_property(csv_property: Wave.CsvProperty) -> String:
	return Properties.get_wave_csv_properties_by_id(_id)[csv_property]


func get_wave_number() -> int:
	return _wave_number


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
func get_wave_path(player: int, is_air: bool) -> Curve2D:
	var idx = wave_paths.find(func(wave_path): \
		wave_path.is_air() == is_air and wave_path.get_player() == player)
	if idx == -1:
		push_error("Could not find wave path for player [%s] and is_air [%s] in " \
			+ "a group of paths [wave_path]." % [player, is_air])
	return wave_paths[idx]


# Returns an array of Modifications that should be
# applied for the specified Creep. This is including
# creep armor, additional HP, and various unique
# effects like 'Regen', 'Mana Shield', 'Wisdom', etc.
func get_modification() -> Array:
	# TODO:
	return []


# Armor type of the creeps
func get_armor_type() -> ArmorType.enm:
	# TODO:
	return ArmorType.enm.LUA


func is_challenge_wave() -> bool:
	return get_wave_number() % 8 == 0


# Returns an array of possible Creep sizes
# which can be spawned in this wave
func get_creep_sizes() -> Array:
	return get_creeps_combination() \
		.map(func(creep): creep.get_creep_size()) \
		.reduce(func(accum: Array, creep_size: int): 
			if not accum.has(creep_size):
				accum.append(creep_size))


# Calculates base HP for a Creep based on 
# the wave number 
func get_base_hp() -> float:
	#TODO: Formula
	return get_wave_number() * 10
