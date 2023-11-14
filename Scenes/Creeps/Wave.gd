class_name Wave
extends Node


signal finished


enum State {
	PENDING,
	SPAWNING,
	SPAWNED,
	FINISHED,
}


const _size_chances: Dictionary = {
	CreepSize.enm.MASS: 15,
	CreepSize.enm.NORMAL: 50,
	CreepSize.enm.AIR: 15,
	CreepSize.enm.BOSS: 20,
}

const _champion_count_chances: Dictionary = {
	CreepSize.enm.MASS: {
		0: 70,
		1: 30,
	},
	CreepSize.enm.NORMAL: {
		0: 42.5,
		1: 30,
		2: 20,
		3: 7.5,
	},
	CreepSize.enm.AIR: {
		0: 100,
	},
	CreepSize.enm.BOSS: {
		0: 100,
	},
}


var _alive_creep_list: Array[Creep] = []
var _level: int
var _race: CreepCategory.enm
var _armor_type: ArmorType.enm
var _wave_path: Path2D
var state: int = Wave.State.PENDING
var _specials: Array[int] = []
var _base_hp: float = 0.0
var _base_armor: float = 0.0
var _creep_combination: Array[CreepSize.enm]
var _creep_size: CreepSize.enm


@onready var _wave_paths: Array = get_tree().get_nodes_in_group("wave_path")


#########################
### Code starts here  ###
#########################


func _init(level: int, difficulty: int):
	_level = level

	_creep_size = Wave._generate_creep_size(_level)
	_race = Wave._generate_creep_race(_creep_size)
	_armor_type = Wave._get_random_armor_type(_level, _creep_size)
	_creep_combination = Wave._generate_creep_combination(_level, _creep_size)
	var wave_has_champions: bool = _creep_combination.has(CreepSize.enm.CHAMPION)
	_specials = WaveSpecial.get_random(_level, _creep_size, wave_has_champions)
	_base_hp = Wave._calculate_base_hp(_level, difficulty)
	_base_armor = Wave._calculate_base_armor(_level, difficulty)

#	NOTE: double the amount of creeps when wave special is
#	"Flock"
	if _specials.has(WaveSpecial.FLOCK):
		var original_combination: Array[CreepSize.enm] = _creep_combination.duplicate()

		for creep_size in original_combination:
			_creep_combination.append(creep_size)


func _ready():
	set_name("Wave")

# 	NOTE: need to init wave path here because wave can't get
# 	wave paths until it's ready in the scene tree.
	_wave_path = Wave._get_wave_path(0, _creep_size, _wave_paths)


#########################
###       Public      ###
#########################


#########################
###      Private      ###
#########################


func _on_creep_tree_exited(creep: Creep):
	_alive_creep_list.erase(creep)

	if _alive_creep_list.is_empty() && state == Wave.State.SPAWNED:
		state = Wave.State.FINISHED
		finished.emit()


#########################
###     Callbacks     ###
#########################


#########################
### Setters / Getters ###
#########################


# Returns a list of scenes used by creeps in this wave
func get_used_scene_list() -> Array[String]:
	var scene_list: Array[String] = []

	for creep_size in _creep_combination:
		var scene_name: String = Wave.get_scene_name_for_creep_type(creep_size, _race)

		if !scene_list.has(scene_name):
			scene_list.append(scene_name)

	return scene_list


func get_creep_race() -> CreepCategory.enm:
	return _race


func get_creep_size() -> CreepSize.enm:
	return _creep_size


# Returns an array of CreepSize enm.that should be spawned
# in the same order as they are stored in this array.
func get_creep_combination() -> Array[CreepSize.enm]:
	return _creep_combination


# [MASS, MASS, MASS, CHAMPION]
# =>
# "3 Mass, 1 Champion"
func get_creep_combination_string() -> String:
	var size_count_map: Dictionary = {}

	for size in _creep_combination:
		if !size_count_map.has(size):
			size_count_map[size] = 0

		size_count_map[size] += 1

#	NOTE: champions go first, order for other sizes doesn't
#	matter
	var size_list_ordered: Array[CreepSize.enm] = [CreepSize.enm.CHAMPION, CreepSize.enm.NORMAL, CreepSize.enm.AIR, CreepSize.enm.MASS, CreepSize.enm.BOSS, CreepSize.enm.CHALLENGE_MASS, CreepSize.enm.CHALLENGE_BOSS]

	var string_split: Array[String] = []

	for size in size_list_ordered:
		if !size_count_map.has(size):
			continue

		var count: int = size_count_map[size]
		var size_string: String = CreepSize.convert_to_colored_string(size)
		var count_and_size_string: String = "[color=GOLD]%d[/color] %s" % [count, size_string]

		string_split.append(count_and_size_string)

	var combination_string: String = ", ".join(string_split)

	return combination_string


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


# Armor type of the creeps
func get_armor_type() -> ArmorType.enm:
	return _armor_type


func get_level() -> int:
	return _level


func get_specials() -> Array[int]:
	return _specials


func get_race() -> CreepCategory.enm:
	return _race


# Returns an array of possible Creep sizes
# which can be spawned in this wave
func get_creep_sizes() -> Array:
	var result = []
	for creep_size in get_creep_combination():
		if not result.has(creep_size):
			result.append(creep_size)
	return result


func get_base_hp() -> float:
	if Config.override_creep_health() != 0:
		var override_creep_health: float = Config.override_creep_health()

		return override_creep_health

	return _base_hp


func get_base_armor() -> float:
	return _base_armor


func add_alive_creep(creep: Creep):
	_alive_creep_list.append(creep)
	creep.tree_exited.connect(_on_creep_tree_exited.bind(creep))


# Calculates base HP for a Creep based on 
# the wave level 
static func _calculate_base_hp(level: int, difficulty: Difficulty.enm) -> float:
	var a: float
	var b: float
	var c: float
	var d: float
	var e: float
	var f: float
	var g: float

	match difficulty:
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

#	NOTE: extra hp multiplier can be found in jass code but
#	it's located far from the code which implements the main
#	health formula. Search for "(.9-" strings to find it in
#	multiple locations.
	var extra_hp_multiplier: float = (0.9 - (level * 0.002))

	var j: int = level - 1
	var health: float = a + j * (b + j * (c + j * (d + j * (e + j * (f + j * g)))))
	health = health * extra_hp_multiplier

	return health


static func _calculate_base_armor(level: int, difficulty: Difficulty.enm) -> float:
	var a: float
	var b: float
	var c: float

	match difficulty:
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

	var j: int = level - 1
	var base_armor: float = a + j * (b + j * c)

	return base_armor


static func _generate_creep_race(creep_size: CreepSize.enm) -> CreepCategory.enm:
	var override_creep_race_string: String = Config.override_creep_race()
	if !override_creep_race_string.is_empty():
		var override_creep_race: CreepCategory.enm = CreepCategory.from_string(override_creep_race_string)

		return override_creep_race

	var size_is_challenge: bool = creep_size == CreepSize.enm.CHALLENGE_MASS || creep_size == CreepSize.enm.CHALLENGE_BOSS

	if size_is_challenge:
		return CreepCategory.enm.CHALLENGE

	var race_list: Array[CreepCategory.enm] = [
		CreepCategory.enm.UNDEAD,
		CreepCategory.enm.MAGIC,
		CreepCategory.enm.NATURE,
		CreepCategory.enm.ORC,
		CreepCategory.enm.HUMANOID,
	]

	var random_race: CreepCategory.enm = race_list.pick_random()

	return random_race


# TODO: handle final wave, should be final boss
static func _generate_creep_size(level: int) -> CreepSize.enm:
	var override_creep_size_string: String = Config.override_creep_size()
	if !override_creep_size_string.is_empty():
		var override_creep_size: CreepSize.enm = CreepSize.from_string(override_creep_size_string)

		return override_creep_size

	var challenge: bool = (level % 8) == 0
	var challenge_mass: bool = (level % 120) % 16 == 0 && (level % 120) != 0

	if challenge:
		if challenge_mass:
			return CreepSize.enm.CHALLENGE_MASS
		else:
			return CreepSize.enm.CHALLENGE_BOSS
	else:
		var random_regular_creep: CreepSize.enm = Utils.random_weighted_pick(_size_chances)

		return random_regular_creep


static func _get_random_armor_type(wave_level: int, creep_size: CreepSize.enm) -> ArmorType.enm:
	var override_creep_armor_string: String = Config.override_creep_armor()
	if !override_creep_armor_string.is_empty():
		var override_creep_armor: ArmorType.enm = ArmorType.from_string(override_creep_armor_string)

		return override_creep_armor

	var is_challenge: bool = CreepSize.is_challenge(creep_size)

	if is_challenge:
		return ArmorType.enm.ZOD

	var regular_armor_list: Array = [
		ArmorType.enm.HEL,
		ArmorType.enm.MYT,
		ArmorType.enm.LUA,
		ArmorType.enm.SOL,
	]

	var can_spawn_sif: bool = wave_level >= 32

	if can_spawn_sif && Utils.rand_chance(Constants.SIF_ARMOR_CHANCE):
		return ArmorType.enm.SIF
	else:
		var random_regular_armor: ArmorType.enm = regular_armor_list.pick_random()

		return random_regular_armor


# Generates a creep combination. If wave contains champions,
# then champions are inserted in regular intervals between
# other creeps.
static func _generate_creep_combination(wave_level: int, creep_size: CreepSize.enm) -> Array[CreepSize.enm]:
	var combination: Array[CreepSize.enm] = []

	var wave_capacity: int = 20 + wave_level / 40
	var champion_count: int = _generate_champion_count(wave_level, creep_size)
	var champion_weight: int = int(CreepSize.get_experience(CreepSize.enm.CHAMPION))
	var unit_weight: int = int(CreepSize.get_experience(creep_size))

	var total_unit_count: int = -1
	var champion_unit_ratio: float = -1
	var regular_unit_ratio: float = -1

	if creep_size == CreepSize.enm.CHALLENGE_BOSS:
		total_unit_count = 1
	elif creep_size == CreepSize.enm.CHALLENGE_MASS:
#		TODO: implement real formula for this. 10 is
#		placeholder value.
		total_unit_count = 10
	elif champion_count > 0:
		total_unit_count = (wave_capacity - champion_count * champion_weight) / unit_weight + champion_count
		champion_unit_ratio = float(total_unit_count) / champion_count
		regular_unit_ratio = float(total_unit_count) / champion_count / 2
	else:
		total_unit_count = wave_capacity / unit_weight

	var champion_count_so_far: int = 0

	for k in range(0, total_unit_count):
		var spawn_champion: bool = int(regular_unit_ratio + champion_unit_ratio * champion_count_so_far - 0.5) == k

		if spawn_champion:
			combination.append(CreepSize.enm.CHAMPION)
			champion_count_so_far = champion_count_so_far + 1
		else:
			combination.append(creep_size)

	return combination


static func _generate_champion_count(wave_level: int, creep_size: CreepSize.enm) -> int:
	var is_challenge: bool = CreepSize.is_challenge(creep_size)

	if is_challenge:
		return 0

	var chance_of_champion_count: Dictionary = _champion_count_chances[creep_size]
	var champion_count: int = Utils.random_weighted_pick(chance_of_champion_count)

	if champion_count > 0:
		champion_count = champion_count + int(wave_level / 120)

	return champion_count


static func _get_wave_path(player: int, creep_size: CreepSize.enm, wave_paths: Array) -> Path2D:
	for path in wave_paths:
		var player_match: bool = path.player == player
		var size_is_air: bool = creep_size == CreepSize.enm.AIR
		var size_match: bool = path.is_air == size_is_air
		var path_match: bool = player_match && size_match

		if path_match:
			return path

	push_error("Could not find wave path for player [%s] and size [%s] in "  % [player, creep_size] \
			+ "a group of paths [wave_path].")
	
	return null


static func get_scene_name_for_creep_type(creep_size: CreepSize.enm, creep_race: CreepCategory.enm) -> String:
	#	TODO: switch to real challenge scenes when they are ready
	if creep_size == CreepSize.enm.CHALLENGE_BOSS:
		return "ChallengeBoss"
	elif creep_size == CreepSize.enm.CHALLENGE_MASS:
		return "ChallengeMass"

	var creep_size_string: String = CreepSize.convert_to_string(creep_size)
	var creep_race_string: String = CreepCategory.convert_to_string(creep_race)
#	NOTE: currently, all creep races use orc scenes. Loading
#	only orc scenes because loading creep scenes is taking a
#	long time in-game and it serves no purpose, because
#	again, all creeps are orcs visually.
# 	Remove this when other creep race scenes are added but
# 	should also improve perfomance so that loading creep
# 	scenes doesn't lag the game.
	if Config.load_only_orc_scenes():
		creep_race_string = CreepCategory.convert_to_string(CreepCategory.enm.ORC)
	var scene_name: String = creep_race_string.capitalize() + creep_size_string.capitalize()

	return scene_name
