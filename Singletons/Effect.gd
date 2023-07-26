extends Node


# NOTE: Enable to check if any effects do not have scenes.
# Disabling for now because at this point most effects won't
# have scenes.
const PRINT_INVALID_PATH_ERROR: bool = false

# Map active effects to integer id's
# 
# NOTE: this is for compatibility with original tower script
# API
var _id_max: int = 0
var _effect_map: Dictionary = {}
var _free_id_list: Array = []

@onready var _effects_container: Node = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("EffectsContainer")


func _ready():
	pass


# NOTE: effect must be an AnimatedSprite2D scene
# NOTE: Effect.createAnimated() in JASS
func create_animated(effect_path: String, x: float, y: float, _z: float, _mystery2: float) -> int:
	var effect_path_exists: bool = ResourceLoader.exists(effect_path)

	var effect_scene: PackedScene
	if effect_path_exists:
		effect_scene = load(effect_path)
	else:
		effect_scene = Globals.placeholder_effect_scene

		if PRINT_INVALID_PATH_ERROR:
			print_debug("Invalid effect path:", effect_path, ". Using placeholder effect.")

	var effect: Node2D = effect_scene.instantiate()

	if !effect is AnimatedSprite2D:
		print_debug("Effect scene must be AnimatedSprite2D. Effect path with problem:", effect_path, ". Using placeholder effect.")

		effect.queue_free()
		effect = Globals.placeholder_effect_scene.instantiate()

	effect.position = Vector2(x, y)
	_effects_container.add_child(effect)

	effect.play()

	var id: int = _make_effect_id()

	_effect_map[id] = effect

	return id


# NOTE: Effect.createSimpleAtUnit() in JASS
func create_simple_at_unit(effect_path: String, unit: Unit) -> int:
	var position: Vector2 = unit.get_visual_position() 
	return create_animated(effect_path, position.x, position.y, 0.0, 0.0)


# NOTE: Effect.createSimpleOnUnit() in JASS
func create_simple_on_unit(effect_path: String, unit: Unit, _body_part: String) -> int:
	return create_simple_at_unit(effect_path, unit)


# NOTE: Effect.createSimpleOnUnit() in JASS
# NOTE: AddSpecialEffectTarget() in JASS()
func add_special_effect_target(effect_path: String, unit: Unit, body_part: String) -> int:
	var position: Vector2 = unit.get_body_part_position(body_part) 
	return create_animated(effect_path, position.x, position.y, 0.0, 0.0)


# NOTE: AddSpecialEffect() in JASS()
func add_special_effect(effect_path: String, x: float, y: float) -> int:
	return create_animated(effect_path, x, y, 0.0, 0.0)


# TODO: implement scale parameter
# NOTE: Effect.createScaled() in JASS()
func create_scaled(effect_path: String, x: float, y: float, z: float, _mystery2: float, _scale: float) -> int:
	return create_animated(effect_path, x, y, z, _mystery2)


# TODO: implement color
# NOTE: Effect.createColored() in JASS()
func create_colored(effect_path: String, x: float, y: float, z: float, _mystery2: float, _scale: float, _color: Color):
	return create_animated(effect_path, x, y, z, _mystery2)


func scale_effect(effect_id: int, scale: float):
	if !_effect_map.has(effect_id):
		return

	var effect = _effect_map[effect_id]
	effect.scale *= scale


# NOTE: effect.setLifetime() in JASS()
func set_lifetime(effect_id: int, lifetime: float):
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_timer_timeout.bind(effect_id))


# NOTE: DestroyEffect() in JASS()
func destroy_effect(effect_id: int):
	if !_effect_map.has(effect_id):
		return

	var effect = _effect_map[effect_id]

# 	NOTE: destroy effect after animation is finished so that
# 	this function can be used to create an effect that is
# 	destroyed after it's done animating
	effect.animation_finished.connect(_on_effect_animation_finished.bind(effect_id))
	effect.animation_looped.connect(_on_effect_animation_finished.bind(effect_id))


# TODO: implement, no idea what this is supposed to do
# NOTE: effect.noDeathAnimation() in JASS()
func no_death_animation(_effect_id: int):
	pass


func _make_effect_id() -> int:
	if !_free_id_list.is_empty():
		var id: int = _free_id_list.pop_back()

		return id
	else:
		var id: int = _id_max
		_id_max += 1

		return id


func _on_lifetime_timer_timeout(effect_id: int):
	_on_effect_animation_finished(effect_id)


func _on_effect_animation_finished(effect_id: int):
	var effect: Node2D = _effect_map[effect_id]
	_effect_map.erase(effect_id)
	effect.queue_free()

	_free_id_list.append(effect_id)
