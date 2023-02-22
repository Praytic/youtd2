extends Node


const placeholder_effect_path: String = "res://Scenes/Effects/GenericMagic.tscn"

onready var _effects_container: Node = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("EffectsContainer")


func _ready():
	pass


func create_animated(effect_path: String, x: float, y: float, _myster1: float, _myster2: float):
	var directory = Directory.new();
	var effect_path_exists: bool = directory.file_exists(effect_path)

	if !effect_path_exists:
		effect_path = placeholder_effect_path
		print_debug("Invalid effect path:", effect_path, ". Using placeholder effect.")
	
	var effect_scene = load(effect_path).instance()
	effect_scene.position = Vector2(x, y)
	_effects_container.call_deferred("add_child", effect_scene)
