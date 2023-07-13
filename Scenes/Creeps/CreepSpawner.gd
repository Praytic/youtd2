extends Node


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


const MASS_SPAWN_DELAY_SEC = 0.2
const NORMAL_SPAWN_DELAY_SEC = 0.9
const CREEP_SCENE_INSTANCES_PATHS = {
	"HumanoidAir": "res://Scenes/Creeps/Instances/Humanoid/HumanoidAirCreep.tscn",
	"HumanoidChampion": "res://Scenes/Creeps/Instances/Humanoid/HumanoidChampionCreep.tscn",
	"HumanoidBoss": "res://Scenes/Creeps/Instances/Humanoid/HumanoidBossCreep.tscn",
	"HumanoidMass": "res://Scenes/Creeps/Instances/Humanoid/HumanoidMassCreep.tscn",
	"HumanoidNormal": "res://Scenes/Creeps/Instances/Humanoid/HumanoidNormalCreep.tscn",
	
	"OrcChampion": "res://Scenes/Creeps/Instances/Orc/OrcChampionCreep.tscn",
	"OrcAir": "res://Scenes/Creeps/Instances/Orc/OrcAirCreep.tscn",
	"OrcBoss": "res://Scenes/Creeps/Instances/Orc/OrcBossCreep.tscn",
	"OrcMass": "res://Scenes/Creeps/Instances/Orc/OrcMassCreep.tscn",
	"OrcNormal": "res://Scenes/Creeps/Instances/Orc/OrcNormalCreep.tscn",
	
	"UndeadChampion": "res://Scenes/Creeps/Instances/Undead/UndeadChampionCreep.tscn",
	"UndeadAir": "res://Scenes/Creeps/Instances/Undead/UndeadAirCreep.tscn",
	"UndeadBoss": "res://Scenes/Creeps/Instances/Undead/UndeadBossCreep.tscn",
	"UndeadMass": "res://Scenes/Creeps/Instances/Undead/UndeadMassCreep.tscn",
	"UndeadNormal": "res://Scenes/Creeps/Instances/Undead/UndeadNormalCreep.tscn",
	
	"MagicNormal": "res://Scenes/Creeps/Instances/Magic/MagicNormalCreep.tscn",
	"MagicChampion": "res://Scenes/Creeps/Instances/Magic/MagicChampionCreep.tscn",
	"MagicAir": "res://Scenes/Creeps/Instances/Magic/MagicAirCreep.tscn",
	"MagicBoss": "res://Scenes/Creeps/Instances/Magic/MagicBossCreep.tscn",
	"MagicMass": "res://Scenes/Creeps/Instances/Magic/MagicMassCreep.tscn",
	
	"NatureAir": "res://Scenes/Creeps/Instances/Nature/NatureAirCreep.tscn",
	"NatureBoss": "res://Scenes/Creeps/Instances/Nature/NatureBossCreep.tscn",
	"NatureMass": "res://Scenes/Creeps/Instances/Nature/NatureMassCreep.tscn",
	"NatureNormal": "res://Scenes/Creeps/Instances/Nature/NatureNormalCreep.tscn",
	"NatureChampion": "res://Scenes/Creeps/Instances/Nature/NatureChampionCreep.tscn",
}


# Dict[scene_name -> Resource]
var _creep_scenes: Dictionary
var _creep_spawn_queue: Array[CreepData]
var _wave_spawn_queue: Array[Wave]

@onready var _timer_between_creeps: Timer = $Timer


func _ready():
	_timer_between_creeps.set_autostart(true)
	_timer_between_creeps.set_one_shot(false)
	
	var regex_search = RegEx.new()
	regex_search.compile("^(?!\\.).*$")
	
	# Load resources of creep scenes for each combination
	# of CreepSize.enm and CreepCategory.enm
	for creep_scene_name in CREEP_SCENE_INSTANCES_PATHS.keys():
		var creep_scene_path = CREEP_SCENE_INSTANCES_PATHS[creep_scene_name]
		_creep_scenes[creep_scene_name] = load(creep_scene_path)
	
	print_verbose("Creep scenes have been loaded.")


func queue_spawn_creep(creep_data: CreepData, wave: Wave):
	assert(creep_data != null, "Tried to spawn null creep.")
	
# 	TODO: rework this so that the logic of "this creep
# 	belongs to this wave" is better expressed. Currently
# 	it's two parallel arrays where creeps are in the same
# 	order as their waves.
	_creep_spawn_queue.push_back(creep_data)
	_wave_spawn_queue.push_back(wave)
	if _timer_between_creeps.is_stopped():
		if creep_data.size == CreepSize.enm.MASS:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		elif creep_data.size == CreepSize.enm.NORMAL:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		print_verbose("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func generate_creep_for_wave(wave: Wave, creep_size) -> CreepData:
	var creep_size_name = Utils.screaming_snake_case_to_camel_case(CreepSize.enm.keys()[creep_size])
	var creep_race_name = Utils.screaming_snake_case_to_camel_case(CreepCategory.enm.keys()[wave.get_race()])
	var creep_scene_name = creep_race_name + creep_size_name

	var creep_data: CreepData = CreepData.new()
	creep_data.scene_name = creep_scene_name
	creep_data.size = creep_size

	return creep_data


func spawn_creep(creep_data: CreepData, wave: Wave):
	if not creep_data:
		print_verbose("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()
		return

	var creep_size: CreepSize.enm = creep_data.size
	var creep_scene_name: String = creep_data.scene_name

	var creep = _creep_scenes[creep_scene_name].instantiate()
	if not creep:
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, wave.get_race()])
	creep.set_path(wave.get_wave_path())
	creep.set_creep_size(creep_size)
	creep.set_armor_type(wave.get_armor_type())
	creep.set_category(wave.get_race())
	creep.set_base_health(wave.get_base_hp())
	creep.set_spawn_level(wave.get_wave_number())
	creep.death.connect(wave._on_Creep_death.bind(creep))
	creep.reached_portal.connect(Callable(wave, "_on_Creep_reached_portal").bind(creep))

	wave.add_alive_creep(creep)

	Utils.add_object_to_world(creep)
	print_verbose("Creep has been spawned [%s]." % creep)

#	NOTE: buffs must be applied after creep has been added to
#	world
	var special_list: Array[int] = wave.get_specials()
	WaveSpecial.apply_to_creep(special_list, creep)


func _on_Timer_timeout():
	var creep = _creep_spawn_queue.pop_front()
	var wave: Wave = _wave_spawn_queue.pop_front()
	if creep == null:
		print_verbose("Creep spawn queue is empty. Nothing to spawn.")
	spawn_creep(creep, wave)
	creep_spawned.emit(creep)
