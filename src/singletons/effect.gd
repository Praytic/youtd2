extends Node


# Functions to create "effects" which are used to add visual
# indicators of buffs and abilities. Functions which take a
# Unit instead of a position will make the effect follow the
# unit.


# NOTE: effect must be an AnimatedSprite2D scene
# NOTE: Effect.createAnimated() in JASS
func create_animated(effect_path: String, effect_pos: Vector3, facing: float) -> int:
	var effects_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/EffectsContainer")
	
	if effects_container == null:
		push_warning("effects_container is null. You can ignore this warning during game restart.")

		return 0

	var id: int = effects_container.create_animated(effect_path, effect_pos, facing)

	return id


# NOTE: Effect.createAnimatedScaled() in JASS
func create_animated_scaled(effect_path: String, effect_pos: Vector3, mystery1: float, _scale: float) -> int:
	return create_animated(effect_path, effect_pos, mystery1)


# NOTE: Effect.createSimple() in JASS
func create_simple(effect_path: String, effect_pos: Vector2) -> int:
	var effect_pos_3d: Vector3 = Vector3(effect_pos.x, effect_pos.y, 0)
	return create_animated(effect_path, effect_pos_3d, 0.0)

# NOTE: Effect.createSimpleAtUnit() in JASS
func create_simple_at_unit(effect_path: String, unit: Unit) -> int:
	return create_simple_on_unit(effect_path, unit, Unit.BodyPart.CHEST)


# NOTE: Effect.createSimpleOnUnit() in JASS
func create_simple_on_unit(effect_path: String, unit: Unit, body_part: Unit.BodyPart) -> int:
	var effects_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/EffectsContainer")
	
	if effects_container == null:
		push_warning("effects_container is null. You can ignore this warning during game restart.")

		return 0

	var id: int = effects_container.create_simple_on_unit(effect_path, unit, body_part)

	return id


# NOTE: AddSpecialEffectTarget() in JASS()
func add_special_effect_target(effect_path: String, unit: Unit, body_part: Unit.BodyPart) -> int:
	return create_simple_on_unit(effect_path, unit, body_part)


# NOTE: AddSpecialEffect() in JASS()
func add_special_effect(effect_path: String, effect_pos: Vector2) -> int:
	var effect_pos_3d: Vector3 = Vector3(effect_pos.x, effect_pos.y, 0)
	return create_animated(effect_path, effect_pos_3d, 0.0)


# NOTE: Effect.createScaled() in JASS()
func create_scaled(effect_path: String, effect_pos: Vector3, facing: float, scale: float) -> int:
	var effect: int = create_animated(effect_path, effect_pos, facing)
	Effect.set_scale(effect, scale)

	return effect


# NOTE: Effect.createColored() in JASS()
func create_colored(effect_path: String, effect_pos: Vector3, facing: float, scale: float, color: Color):
	var effect: int = create_animated(effect_path, effect_pos, facing)
	Effect.set_scale(effect, scale)
	Effect.set_color(effect, color)

	return effect


# NOTE: effect.setScale() in JASS()
func set_scale(effect_id: int, scale: float):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	effect.scale = Vector2.ONE * scale


func set_color(effect_id: int, color: Color):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	effect.modulate = color


# NOTE: effect.setLifetime() in JASS()
func set_lifetime(effect_id: int, lifetime: float):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	var timer: ManualTimer = Utils.create_timer(lifetime, self)
	timer.timeout.connect(_on_lifetime_timer_timeout.bind(effect_id))


# NOTE: effect.setAnimationSpeed() in JASS()
func set_animation_speed(effect_id: int, speed: float):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	var effect_sprite: AnimatedSprite2D = effect as AnimatedSprite2D
	effect_sprite.speed_scale = speed


# NOTE: Effect.destroy() and DestroyEffect() in JASS()
func destroy_effect(effect_id: int):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	effect.queue_free()


# NOTE: Effect.destroy() and DestroyEffect() in JASS()
# 
# Call this instead of destroy_effect() if the script calls
# destroy f-n right after creating the effect.
# 
# NOTE: not sure how original JASS scripts determined
# whether to destroy an effect immediately or after
# animation has finished. All the scripts call the same f-n.
func destroy_effect_after_its_over(effect_id: int):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

# 	NOTE: destroy effect after animation is finished so that
# 	this function can be used to create an effect that is
# 	destroyed after it's done animating
	effect.animation_finished.connect(_on_effect_animation_finished.bind(effect_id))
	effect.animation_looped.connect(_on_effect_animation_finished.bind(effect_id))


func set_position(effect_id: int, pos_wc3: Vector2):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	var pos_wc3_3d: Vector3 = Vector3(pos_wc3.x, pos_wc3.y, 0)
	var pos_canvas: Vector2 = VectorUtils.wc3_to_canvas(pos_wc3_3d)
	effect.position = pos_canvas


#########################
###      Private      ###
#########################

func _get_effect(effect_id: int) -> Node2D:
	var effects_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/EffectsContainer")
	
	if effects_container == null:
		push_warning("effects_container is null. You can ignore this warning during game restart.")

		return null

	var effect: Node2D = effects_container.get_effect(effect_id)

	return effect


#########################
###     Callbacks     ###
#########################

func _on_lifetime_timer_timeout(effect_id: int):
	destroy_effect(effect_id)


func _on_effect_animation_finished(effect_id: int):
	destroy_effect(effect_id)
