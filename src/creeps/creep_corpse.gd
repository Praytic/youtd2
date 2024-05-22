class_name CreepCorpse extends Unit


# Corpse visual created after creep dies. Fades away slowly
# then disappears. Note that creep corpses are used by some
# towers, for example the Undistrubed Crypt tower deals aoe
# damage centered on corpse positions.


const DURATION: float = 10
const RANDOM_OFFSET: float = 5

@export var _sprite: AnimatedSprite2D
@export var _visual: Node2D


func _ready():
	super()

	_set_visual_node(_visual)

#	Move corpse to a random small offset during death
#	animation. Otherwise corpses line up perfectly and it
#	looks weird.
# 
# 	NOTE: it's ok to use tween and local_rng here because
# 	position of sprite doesn't affect game logic in any way.
# 	Note that position of the corpse parent node is still
# 	important and affects game logic.
	var position_tween = create_tween()
	var random_offset_top_down: Vector2 = Vector2(
		RANDOM_OFFSET * Globals.local_rng.randf_range(-1, 1),
		RANDOM_OFFSET * Globals.local_rng.randf_range(-1, -1))
	var random_offset_canvas: Vector2 = VectorUtils.top_down_to_canvas(random_offset_top_down)
	var final_pos: Vector2 = _sprite.position + random_offset_canvas
	position_tween.tween_property(_sprite, "position",
		final_pos,
		0.2 * DURATION).set_trans(Tween.TRANS_LINEAR)

	var fade_tween = create_tween()
	fade_tween.tween_property(_sprite, "modulate",
		Color(_sprite.modulate.r, _sprite.modulate.g, _sprite.modulate.b, 0),
		0.2 * DURATION).set_delay(0.8 * DURATION).set_trans(Tween.TRANS_LINEAR)
	fade_tween.finished.connect(_on_fade_finished)


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


func _on_fade_finished():
	remove_from_game()


# NOTE: need to add to group after animation is finished and
# not inside _ready() so that this node is considered a
# "corpse" only after the animation is finished. This
# means that this node won't be visible when towers search
# for corpses via Iterate. Otherwise, there are problems
# with towers like "Plagued Crypt" which destroy corpses
# too early before death animation is finished.
func _on_sprite_2d_animation_finished():
	add_to_group("corpses")


#########################
###       Static      ###
#########################

static func make(player: Player, sprite: AnimatedSprite2D, death_animation: String) -> CreepCorpse:
	var corpse: Node2D = Preloads.corpse_scene.instantiate()
	corpse.set_player(player)
	corpse._setup_sprite(sprite, death_animation)

	return corpse
