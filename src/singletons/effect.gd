extends Node


# Functions to create "effects" which are used to add visual
# indicators of buffs and abilities.

# NOTE: effect scene args must be AnimatedSprite2D


# NOTE: Effect.createAnimated() in JASS
func create_animated(effect_path: String, effect_pos: Vector3, facing: float) -> int:
	var effects_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/EffectsContainer")
	
	if effects_container == null:
		push_warning("effects_container is null. You can ignore this warning during game restart.")

		return 0

	var id: int = effects_container.create_animated(effect_path, effect_pos, facing)
	set_auto_destroy_enabled(id, true)

	return id


# NOTE: Effect.createAnimatedScaled() in JASS
func create_animated_scaled(effect_path: String, effect_pos: Vector3, facing: float, scale: float) -> int:
	var effect: int = create_animated(effect_path, effect_pos, facing)
	Effect.set_scale(effect, scale)

	return effect


# NOTE: Effect.createSimple() in JASS
func create_simple(effect_path: String, effect_pos: Vector2) -> int:
	var effect_pos_3d: Vector3 = Vector3(effect_pos.x, effect_pos.y, 0)
	return create_animated(effect_path, effect_pos_3d, 0.0)

# Creates an effect at position of Unit. Effect will *not*
# follow the unit if it moves.
# NOTE: Effect.createSimpleAtUnit() in JASS
func create_simple_at_unit(effect_path: String, unit: Unit, body_part: Unit.BodyPart = Unit.BodyPart.CHEST) -> int:
	var effect_pos: Vector3 = unit.get_body_part_position(body_part)

	return create_animated(effect_path, effect_pos, 0.0)


# Creates an effect on the Unit. Effect will follow the unit
# if it moves. The effect will also go away if the unit dies.
# NOTE: Effect.createSimpleOnUnit() in JASS
func create_simple_at_unit_attached(effect_path: String, unit: Unit, body_part: Unit.BodyPart = Unit.BodyPart.CHEST) -> int:
	var effects_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/EffectsContainer")
	
	if effects_container == null:
		push_warning("effects_container is null. You can ignore this warning during game restart.")

		return 0

	var id: int = effects_container.create_simple_at_unit_attached(effect_path, unit, body_part)
	set_auto_destroy_enabled(id, true)

	return id


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
	
	var effects_container: Node = get_tree().get_root().get_node_or_null("GameScene/World/EffectsContainer")
	
	if effects_container == null:
		push_warning("effects_container is null. You can ignore this warning during game restart.")

		return

	var original_scale: Vector2 = effects_container.get_effect_original_scale(effect_id)
	
	effect.scale = original_scale * scale


func set_color(effect_id: int, color: Color):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	effect.modulate = color


# This makes the effect be automatically destroyed after
# given lifetime period.
# NOTE: effect.setLifetime() in JASS()
func set_lifetime(effect_id: int, lifetime: float):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	set_auto_destroy_enabled(effect_id, false)

	var timer: ManualTimer = Utils.create_timer(lifetime, self)
	timer.timeout.connect(_on_lifetime_timer_timeout.bind(effect_id))


# NOTE: effect.setAnimationSpeed() in JASS()
func set_animation_speed(effect_id: int, speed: float):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	var effect_sprite: AnimatedSprite2D = effect as AnimatedSprite2D
	effect_sprite.speed_scale = speed


# NOTE: this f-n works differently than in original youtd.
# In original youtd, calling destroy() would schedule effect
# to be destroyed once the animation finished. In youtd2,
# calling destroy_effect() will remove the effect instantly.
# Also note that in youtd2 effects are by default scheduled
# to be destroyed when animation finishes.
# 
# NOTE: Effect.destroy() and DestroyEffect() in JASS()
func destroy_effect(effect_id: int):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	effect.queue_free()


# Changes whether effect should be automatically destroyed
# once it's animation ends. This is enabled by default.
func set_auto_destroy_enabled(effect_id: int, enabled: bool):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	if enabled:
		if !effect.animation_finished.is_connected(_on_effect_animation_finished):
			effect.animation_finished.connect(_on_effect_animation_finished.bind(effect_id))
		if !effect.animation_looped.is_connected(_on_effect_animation_finished):
			effect.animation_looped.connect(_on_effect_animation_finished.bind(effect_id))
	else:
		if effect.animation_finished.is_connected(_on_effect_animation_finished):
			effect.animation_finished.disconnect(_on_effect_animation_finished)
		if effect.animation_looped.is_connected(_on_effect_animation_finished):
			effect.animation_looped.disconnect(_on_effect_animation_finished)


func set_position(effect_id: int, pos_wc3: Vector2):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	var pos_wc3_3d: Vector3 = Vector3(pos_wc3.x, pos_wc3.y, 0)
	var pos_canvas: Vector2 = VectorUtils.wc3_to_canvas(pos_wc3_3d)
	effect.position = pos_canvas


func set_z_index(effect_id: int, z_index):
	var effect: Node2D = _get_effect(effect_id)
	if effect == null:
		return

	effect.z_index = z_index


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
