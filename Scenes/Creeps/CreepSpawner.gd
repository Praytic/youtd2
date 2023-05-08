extends Node


signal creep_spawned(creep: Creep)
signal all_creeps_spawned


const MASS_SPAWN_DELAY_SEC = 0.2
const NORMAL_SPAWN_DELAY_SEC = 0.9
const CREEP_SCENE_INSTANCES_PATHS = {
	"HumanoidAir": "res://Scenes/Creeps/Instances/HumanoidAir.tscn",
	"HumanoidChampion": "res://Scenes/Creeps/Instances/HumanoidChampion.tscn",
	"HumanoidBoss": "res://Scenes/Creeps/Instances/HumanoidBoss.tscn",
	"HumanoidMass": "res://Scenes/Creeps/Instances/HumanoidMass.tscn",
	"HumanoidNormal": "res://Scenes/Creeps/Instances/HumanoidNormal.tscn",
	
	"OrcChampion": "res://Scenes/Creeps/Instances/OrcChampion.tscn",
	"OrcAir": "res://Scenes/Creeps/Instances/OrcAir.tscn",
	"OrcBoss": "res://Scenes/Creeps/Instances/OrcBoss.tscn",
	"OrcMass": "res://Scenes/Creeps/Instances/OrcMass.tscn",
	"OrcNormal": "res://Scenes/Creeps/Instances/OrcNormal.tscn",
	
	"UndeadChampion": "res://Scenes/Creeps/Instances/UndeadChampion.tscn",
	"UndeadAir": "res://Scenes/Creeps/Instances/UndeadAir.tscn",
	"UndeadBoss": "res://Scenes/Creeps/Instances/UndeadBoss.tscn",
	"UndeadMass": "res://Scenes/Creeps/Instances/UndeadMass.tscn",
	"UndeadNormal": "res://Scenes/Creeps/Instances/UndeadNormal.tscn",
	
	"MagicNormal": "res://Scenes/Creeps/Instances/MagicNormal.tscn",
	"MagicChampion": "res://Scenes/Creeps/Instances/MagicChampion.tscn",
	"MagicAir": "res://Scenes/Creeps/Instances/MagicAir.tscn",
	"MagicBoss": "res://Scenes/Creeps/Instances/MagicBoss.tscn",
	"MagicMass": "res://Scenes/Creeps/Instances/MagicMass.tscn",
	
	"NatureAir": "res://Scenes/Creeps/Instances/NatureAir.tscn",
	"NatureBoss": "res://Scenes/Creeps/Instances/NatureBoss.tscn",
	"NatureMass": "res://Scenes/Creeps/Instances/NatureMass.tscn",
	"NatureNormal": "res://Scenes/Creeps/Instances/NatureNormal.tscn",
	"NatureChampion": "res://Scenes/Creeps/Instances/NatureChampion.tscn",
}


# Dict[scene_name -> Resource]
var _creep_scenes: Dictionary
var _creep_spawn_queue: Array
var _wave_spawn_queue: Array

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


func queue_spawn_creep(creep: Creep, wave: Wave):
	assert(creep != null, "Tried to spawn null creep.")
	
# 	TODO: rework this so that the logic of "this creep
# 	belongs to this wave" is better expressed. Currently
# 	it's two parallel arrays where creeps are in the same
# 	order as their waves.
	_creep_spawn_queue.push_back(creep)
	_wave_spawn_queue.push_back(wave)
	if _timer_between_creeps.is_stopped():
		if creep.get_size() == CreepSize.enm.MASS:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		elif creep.get_size() == CreepSize.enm.NORMAL:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		print_verbose("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func generate_creep_for_wave(wave: Wave, creep_size) -> Creep:
	var creep_size_name = Utils.screaming_snake_case_to_camel_case(CreepSize.enm.keys()[creep_size])
	var creep_race_name = Utils.screaming_snake_case_to_camel_case(CreepCategory.enm.keys()[wave.get_race()])
	var creep_scene_name = creep_race_name + creep_size_name
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
	return creep


func spawn_creep(creep: Creep, wave: Wave):
	if not creep:
		print_verbose("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()
		return
	
	Utils.add_object_to_world(creep)
	print_verbose("Creep has been spawned [%s]." % creep)

#	NOTE: buffs must be applied after creep has been added to
#	world
	var special_list: Array[int] = wave.get_specials()
	for special in special_list:
		WaveSpecial.apply_to_creep(special, creep)


func _on_Timer_timeout():
	var creep = _creep_spawn_queue.pop_front()
	var wave: Wave = _wave_spawn_queue.pop_front()
	if creep == null:
		print_verbose("Creep spawn queue is empty. Nothing to spawn.")
	spawn_creep(creep, wave)
	creep_spawned.emit(creep)
