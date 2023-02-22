extends Node


const placeholder_effect_path: String = "res://Scenes/Effects/GenericMagic.tscn"

# Map active effects to integer id's
# 
# NOTE: this is for compatibility with original tower script
# API
var id_max: int = 0
var _effect_map: Dictionary = {}
var free_id_list: Array = []

onready var _effects_container: Node = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("EffectsContainer")


func _ready():
	pass


func create_animated(effect_path: String, x: float, y: float, _mystery1: float, _mystery2: float) -> int:
	var directory = Directory.new();
	var effect_path_exists: bool = directory.file_exists(effect_path)

	if !effect_path_exists:
		effect_path = placeholder_effect_path
		print_debug("Invalid effect path:", effect_path, ". Using placeholder effect.")
	
	var effect_scene = load(effect_path).instance()
	effect_scene.position = Vector2(x, y)
	_effects_container.call_deferred("add_child", effect_scene)

	var id: int = make_effect_id()

	_effect_map[id] = effect_scene

	return id


func destroy_effect(effect_id: int):
	if !_effect_map.has(effect_id):
		return

	var effect = _effect_map[effect_id]
	effect.queue_free()


func make_effect_id() -> int:
	if !free_id_list.empty():
		var id: int = free_id_list.pop_back()

		return id
	else:
		var id: int = id_max
		id_max += 1

		return id
