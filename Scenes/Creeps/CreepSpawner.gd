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

@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var gold_control = get_tree().current_scene.get_node("%GoldControl")
@onready var object_ysort: Node2D = get_tree().current_scene.get_node("%Map/ObjectYSort")
@onready var _timer_between_creeps: Timer = $Timer


func _ready():
	_timer_between_creeps.set_autostart(true)
	_timer_between_creeps.set_one_shot(false)
	
	var regex_search = RegEx.new()
	regex_search.compile("^(?!\\.).*$")
	
	# Load resources of creep scenes for each combination
	# of Creep.Size and Creep.Category
	for creep_scene_name in CREEP_SCENE_INSTANCES_PATHS.keys():
		var creep_scene_path = CREEP_SCENE_INSTANCES_PATHS[creep_scene_name]
		_creep_scenes[creep_scene_name] = load(creep_scene_path)
	
	Utils.log_debug("Creep scenes have been loaded.")


func queue_spawn_creep(creep: Creep):
	_creep_spawn_queue.push_back(creep)
	if _timer_between_creeps.is_stopped():
		if creep.get_creep_size() == Creep.Size.MASS:
			_timer_between_creeps.set_wait_time(MASS_SPAWN_DELAY_SEC)
		elif creep.get_creep_size() == Creep.Size.NORMAL:
			_timer_between_creeps.set_wait_time(NORMAL_SPAWN_DELAY_SEC)
		Utils.log_debug("Start creep spawn timer with delay [%s]." % _timer_between_creeps.get_wait_time())
		_timer_between_creeps.start()


func generate_creep_for_wave(wave: Wave, creep_size) -> Creep:
	var creep_size_name = Utils.screaming_snake_case_to_camel_case(Creep.Size.keys()[creep_size])
	var creep_race_name = Utils.screaming_snake_case_to_camel_case(Creep.Category.keys()[wave.get_race()])
	var creep_scene_name = creep_race_name + creep_size_name
	var creep = _creep_scenes[creep_scene_name].instantiate()
	if not creep:
		push_error("Could not find a scene for creep size [%s] and race [%]." % [creep_size, wave.get_race()])
	creep.set_path(wave.get_wave_path())
	creep.set_creep_size(creep_size)
	creep.set_armor_type(wave.get_armor_type())
	creep.set_category(wave.get_race())
	creep.set_base_health(wave.get_base_hp())
	creep.death.connect(wave._on_Creep_death.bind(creep))
	creep.reached_portal.connect(Callable(wave, "_on_Creep_reached_portal").bind(creep))
	return creep


func spawn_creep(creep: Creep):
	if not creep:
		Utils.log_debug("Stop creep spawn. Queue is exhausted.")
		_timer_between_creeps.stop()
		all_creeps_spawned.emit()
		return
	
	creep.death.connect(Callable(item_control._on_Creep_death.bind(creep)))
	creep.death.connect(Callable(gold_control._on_Creep_death.bind(creep)))
	object_ysort.add_child(creep, true)
	Utils.log_debug("Creep has been spawned [%s]." % creep)


func _on_Timer_timeout():
	var creep = _creep_spawn_queue.pop_front()
	spawn_creep(creep)
	creep_spawned.emit(creep)
