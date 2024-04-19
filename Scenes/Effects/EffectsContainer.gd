extends Node2D


# Stores effects as children and also maps them to id's. Use
# globally via Effects autoload.


# Map active effects to integer id's
# 
# NOTE: this is for compatibility with original tower script
# API
var _id_max: int
var _effect_map: Dictionary
var _free_id_list: Array


# NOTE: Enable to check if any effects do not have scenes.
# This is currently disabled because at this point most
# effects won't have scenes and you will get hundreds of
# errors.
const PRINT_INVALID_PATH_ERROR: bool = false


#########################
###       Public      ###
#########################

# NOTE: effect must be an AnimatedSprite2D scene
func create_animated(effect_path: String, x: float, y: float, z: float, _facing: float) -> int:
	var id: int = _create_internal(effect_path)
	var effect: Node2D = _effect_map[id]
	var pos_wc3: Vector3 = Vector3(x, y, z)
	var pos_canvas: Vector2 = VectorUtils.wc3_pos_to_canvas_pos(pos_wc3)
	effect.position = pos_canvas
	add_child(effect)
	effect.play()

	return id


func create_simple_on_unit(effect_path: String, unit: Unit, body_part: Unit.BodyPart) -> int:
	var id: int = _create_internal(effect_path)
	var effect: Node2D = _effect_map[id]

	var body_part_offset: Vector2 = unit.get_body_part_offset(body_part)
	effect.offset += body_part_offset / effect.scale.y

	var unit_visual: Node2D = unit.get_visual_node()
	if unit_visual != null:
		unit_visual.add_child(effect)
		effect.play()
	else:
		push_error("Couldn't add effect to unit because unit_visual is null. Make sure that Unit._set_visual_node() is called before any possible effects.")

	return id


func get_effect(effect_id: int) -> Node2D:
	if !_effect_map.has(effect_id):
		return null

#	NOTE: effects maybe become invalid if unit which carries
#	the effect dies. Then a timer for destroying effect may
#	trigger a call to get_effect. In such cases, clean up
#	the effect and return null.
	if !is_instance_valid(_effect_map[effect_id]):
		_effect_map.erase(effect_id)

		return null

	var effect: Node2D = _effect_map[effect_id]

	return effect


#########################
###      Private      ###
#########################

func _create_internal(effect_path: String) -> int:
	var effect_path_exists: bool = ResourceLoader.exists(effect_path)

	var effect_scene: PackedScene
	if effect_path_exists:
		effect_scene = load(effect_path)
	else:
		effect_scene = Preloads.placeholder_effect_scene

		if PRINT_INVALID_PATH_ERROR:
			print_debug("Invalid effect path:", effect_path, ". Using placeholder effect.")

	var effect: Node2D = effect_scene.instantiate()

	if !effect is AnimatedSprite2D:
		print_debug("Effect scene must be AnimatedSprite2D. Effect path with problem:", effect_path, ". Using placeholder effect.")

		effect.queue_free()
		effect = Preloads.placeholder_effect_scene.instantiate()

	var id: int = _make_effect_id()
	_effect_map[id] = effect

	return id


func _make_effect_id() -> int:
	if !_free_id_list.is_empty():
		var id: int = _free_id_list.pop_back()

		return id
	else:
		var id: int = _id_max
		_id_max += 1

		return id
