class_name CreepCorpse extends Unit


# Corpse visual created after creep dies. Fades away slowly
# then disappears.
# 
# NOTE: this code is very easy to change in such a way that
# it creates a new desync source. It looks like it's visuals
# only but it's not - it affects game logic sometimes.
# Corpses are used by Undistrubed Crypt tower to deal AoE
# damage centered on corpse positions. Therefore, corpse
# properties like position and duration MUST be synced with
# the game client and game speed. That is why a ManualTimer
# is used for expiry instead of a tween.
# 
# Note that for the position and modulate of the sprite (not
# root node), it's ok to use tweens because these properties
# won't have any effect on game logic. But these tweens do
# need to be synced to game speed - otherwise it looks weird
# on fast game speeds.


const DURATION: float = 10
const RANDOM_OFFSET: float = 5

@export var _sprite: AnimatedSprite2D
@export var _visual: Node2D
@export var _expire_timer: ManualTimer


#########################
###     Built-in      ###
#########################

func _ready():
	super()

	add_to_group("corpses")

	_set_visual_node(_visual)
	
	_expire_timer.start(DURATION)

	var game_speed: int = Globals.get_update_ticks_per_physics_tick()

#	Move corpse to a random small offset during death
#	animation. Otherwise corpses line up perfectly and it
#	looks weird.
	var position_tween = create_tween()
	position_tween.set_speed_scale(game_speed)
	var random_offset_top_down: Vector2 = Vector2(
		RANDOM_OFFSET * Globals.local_rng.randf_range(-1, 1),
		RANDOM_OFFSET * Globals.local_rng.randf_range(-1, -1))
	var random_offset_canvas: Vector2 = VectorUtils.top_down_to_canvas(random_offset_top_down)
	var final_pos: Vector2 = _sprite.position + random_offset_canvas
	position_tween.tween_property(_sprite, "position",
		final_pos,
		0.2 * DURATION).set_trans(Tween.TRANS_LINEAR)

	var fade_tween = create_tween()
	fade_tween.set_speed_scale(game_speed)
	fade_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		0.2 * DURATION).set_delay(0.8 * DURATION).set_trans(Tween.TRANS_LINEAR)


#########################
###      Private      ###
#########################

# Copies sprite from creep and starts the death animation.
# NOTE: need to copy original sprite's position and scale to
# correctly display the same thing.
func _setup_sprite(creep_sprite: CreepSprite, death_animation: String):
	_sprite.sprite_frames = creep_sprite.sprite_frames.duplicate()
	_sprite.scale = creep_sprite.scale
#	NOTE: need to copy position of sprite because creep
#	sprites are centered via position
	_sprite.position = creep_sprite.position
	_sprite.sprite_frames.set_animation_loop(death_animation, false)
#	NOTE: play death animation with random speed to make
#	them look more diverse
	_sprite.set_speed_scale(Globals.synced_rng.randf_range(1.0, 1.6))
	var animation_offset: Vector2 = creep_sprite.get_offset_for_animation(death_animation)
	_sprite.set_offset(animation_offset)
	_sprite.play(death_animation)


#########################
###     Callbacks     ###
#########################

func _on_expire_timer_timeout():
	remove_from_game()


#########################
###       Static      ###
#########################

static func make(player: Player, sprite: AnimatedSprite2D, death_animation: String) -> CreepCorpse:
	var corpse: Node2D = Preloads.corpse_scene.instantiate()
	corpse.set_player(player)
	corpse._setup_sprite(sprite, death_animation)

	return corpse
