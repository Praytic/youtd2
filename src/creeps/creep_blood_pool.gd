extends Node2D


# Corpse visual created after creep dies. Fades away slowly
# then disappears. Note that this is not the corpse.


const DURATION: float = 60

@export var _sprite: Sprite2D


func _ready():
#	Start out transparent
	_sprite.modulate.a = 0

#	NOTE: draw blood pool between floor tile and creep
#	corpse
	_sprite.z_index = -1


#	Randomize properties of blood pool to make them look
#	varied
	var random_offset: Vector2 = Vector2(Globals.synced_rng.randf_range(-10, 10), Globals.synced_rng.randf_range(-10, 10))
	_sprite.position += random_offset

	var random_scale: Vector2 = Vector2(Globals.synced_rng.randf_range(0.95, 1.05), Globals.synced_rng.randf_range(0.95, 1.05)) * Globals.synced_rng.randf_range(0.7, 1.0)
	_sprite.scale = random_scale

	_sprite.flip_h = Utils.rand_chance(Globals.synced_rng, 0.5)
	_sprite.flip_v = Utils.rand_chance(Globals.synced_rng, 0.5)

	var transparency_max: float = Globals.synced_rng.randf_range(0.4, 0.6)

# 	Blood pool fades in shortly after creep death animation
# 	falls to the ground.
# 	Then it slowly fades away.
	var game_speed: int = Globals.get_update_ticks_per_physics_tick()
	var modulate_tween = create_tween()
	modulate_tween.set_speed_scale(game_speed)
	modulate_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, transparency_max), 1.0).set_delay(1.0)
	modulate_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		0.6 * DURATION).set_delay(0.4 * DURATION).set_trans(Tween.TRANS_LINEAR)
	modulate_tween.finished.connect(_on_fade_finished)


func _on_fade_finished():
	queue_free()
