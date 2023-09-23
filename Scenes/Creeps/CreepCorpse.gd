extends Unit


# Corpse visual created after creep dies. Fades away slowly
# then disappears. Note that creep corpses are used by some
# towers, for example the Undistrubed Crypt tower deals aoe
# damage centered on corpse positions.


const DURATION: float = 10

@export var _sprite: AnimatedSprite2D


func _ready():
	super()

	add_to_group("corpses")
	_set_visual_node(_sprite)

	var fade_tween = create_tween()
	fade_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		0.2 * DURATION).set_delay(0.8 * DURATION).set_trans(Tween.TRANS_LINEAR)
	fade_tween.finished.connect(on_fade_finished)


# Copies sprite from creep and starts the death animation.
# NOTE: need to copy original sprite's position and scale to
# correctly display the same thing.
func setup_sprite(creep_sprite: CreepSprite, death_animation: String):
	_sprite.sprite_frames = creep_sprite.sprite_frames.duplicate()
	_sprite.scale = creep_sprite.scale
	_sprite.position = creep_sprite.position
	_sprite.sprite_frames.set_animation_loop(death_animation, false)
#	NOTE: play death animation with random speed to make
#	them look more diverse
	_sprite.set_speed_scale(randf_range(0.6, 1.0))
	var animation_offset: Vector2 = creep_sprite.get_offset_for_animation(death_animation)
	_sprite.set_offset(animation_offset)
	_sprite.play(death_animation)


func on_fade_finished():
	queue_free()
