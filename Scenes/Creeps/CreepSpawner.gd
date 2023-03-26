extends Node


signal spawned(creep: Creep)
signal progress_changed(progress_string)


const CREEP_SCENE_INSTANCES_PATH = "res://Scenes/Creeps/Instances/"


# Dict[scene_name -> Resource]
var _creep_scenes: Dictionary


@onready var item_control = get_tree().current_scene.get_node("%ItemControl")
@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")


func _ready():
	# Load resources of creep scenes for each combination
	# of Creep.Size and Creep.Category
	var creep_scenes = Utils.list_files_in_directory(CREEP_SCENE_INSTANCES_PATH)
	for creep_scene_path in creep_scenes:
		var creep_scene_name = Utils.get_scene_name_from_path(creep_scene_path)
		var preloaded_creep_scene = load(creep_scene_path)
		_creep_scenes[creep_scene_name] = preloaded_creep_scene


func spawn_creep(creep: Creep):
#	var creep_instance = get_creep_template(creep_size, creep_race).instantiate()
#	creep_instance.init(path_curve, creep_size, creep_race, creep_armor_type)
#	queue
	object_ysort.add_child(creep)
	creep.death.connect(Callable(item_control, "_on_Creep_death"))
	spawned.emit(creep)


func get_creep_scene(creep_size: Creep.Size, creep_race: Creep.Category) -> PackedScene:
	var instance
	var creep_size_name = Utils.screaming_snake_case_to_camel_case(Creep.Size.get(creep_size))
	var creep_race_name = Utils.screaming_snake_case_to_camel_case(Creep.Category.get(creep_race))
	var creep_scene_name = creep_race_name + creep_size_name
	var creep_scene = _creep_scenes[creep_scene_name]
	return creep_scene
