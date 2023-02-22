extends Node


const placeholder_effect_path: String = "res://Scenes/Effects/GenericMagic.tscn"

# NOTE: Enable to check if any effects do not have scenes.
# Disabling for now because at this point most effects won't
# have scenes.
const PRINT_INVALID_PATH_ERROR: bool = false

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


# NOTE: effect must be an AnimatedSprite scene
func create_animated(effect_path: String, x: float, y: float, _mystery1: float, _mystery2: float) -> int:
	var directory = Directory.new();
	var effect_path_exists: bool = directory.file_exists(effect_path)

	if !effect_path_exists:
		effect_path = placeholder_effect_path

		if PRINT_INVALID_PATH_ERROR:
			print_debug("Invalid effect path:", effect_path, ". Using placeholder effect.")
	
	var effect_scene = load(effect_path).instance()
	effect_scene.position = Vector2(x, y)
	_effects_container.call_deferred("add_child", effect_scene)

	effect_scene.play()

	var id: int = make_effect_id()

	_effect_map[id] = effect_scene

	return id


func create_simple_at_unit(effect_path: String, unit: Unit) -> int:
	return create_animated(effect_path, unit.position.x, unit.position.y, 0.0, 0.0)


func destroy_effect(effect_id: int):
	if !_effect_map.has(effect_id):
		return

	var effect = _effect_map[effect_id]

# 	NOTE: destroy effect after animation is finished so that
# 	this function can be used to create an effect that is
# 	destroyed after it's done animating
	effect.connect("animation_finished", self, "_on_effect_animation_finished", [effect])


func make_effect_id() -> int:
	if !free_id_list.empty():
		var id: int = free_id_list.pop_back()

		return id
	else:
		var id: int = id_max
		id_max += 1

		return id


func _on_effect_animation_finished(effect):
	effect.queue_free()
