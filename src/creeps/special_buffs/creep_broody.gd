class_name CreepBroody extends BuffType


const EGG_SCALE_MIN: float = 0.6
const EGG_SCALE_MAX: float = 1.0
const EGG_GROW_TIME: float = 3.0

const LESSER_HATCHLING_COUNT: int = 5
const LESSER_HATCHLING_HEALTH: float = 0.02
const LESSER_HATCHLING_SCALE: float = 0.3
const LESSER_HATCHLING_RANDOM_OFFSET: float = 100
const GREATER_HATCHLING_HEALTH: float = 0.10
const GREATER_HATCHLING_SCALE: float = 0.6


func _init(parent: Node):
	super("creep_broody", 0, 0, true, parent)

	add_event_on_create(on_create)


func on_create(event: Event):
	var autocast: Autocast = Autocast.make_from_id(171, self)
	var buff: Buff = event.get_buff()
	var creep: Unit = buff.get_buffed_unit()
	creep.add_autocast(autocast)


func on_autocast(event: Event):
#	Lay an egg
	var autocast: Autocast = event.get_autocast_type()
	var caster: Creep = autocast.get_caster()
	var caster_pos: Vector2 = caster.get_position_wc3_2d()
	var egg_effect: int = Effect.create_animated("res://src/effects/barrel.tscn", Vector3(caster_pos.x, caster_pos.y, 0), 0)
	Effect.set_auto_destroy_enabled(egg_effect, false)
	Effect.set_scale(egg_effect, EGG_SCALE_MIN)
	Effect.set_color(egg_effect, Color.GREEN)

#	Save properties of caster
	var caster_scene_path: String = caster.get_scene_file_path()
	var caster_scene: PackedScene = load(caster_scene_path)
	var caster_path: Path2D = caster.get_move_path()
	var player: Player = caster.get_player()
	var caster_armor_type: ArmorType.enm = caster.get_armor_type()
	var caster_race: CreepCategory.enm = caster.get_category()
	var caster_size: CreepSize.enm = caster.get_size()
	var caster_health: float = caster.get_overall_health()
	var caster_armor: float = caster.get_base_armor()
	var caster_level: int = caster.get_spawn_level()
	var caster_path_index: int = caster._current_path_index

#	Add delay before spawning hatchlings. Increase egg scale
#	while waiting.
	for i in range(0, 5):
		var sleep_time: float = EGG_GROW_TIME / 6
		await Utils.create_manual_timer(sleep_time, self).timeout

		var egg_grow_progress: float = i / 6.0
		var egg_scale: float = EGG_SCALE_MIN + egg_grow_progress * (EGG_SCALE_MAX - EGG_SCALE_MIN)
		Effect.set_scale(egg_effect, egg_scale)

	Effect.destroy_effect(egg_effect)

	if !Utils.unit_is_valid(caster):
		return

#	Create hatchlings
	var hatchling_type_is_lesser: int = Utils.rand_chance(Globals.synced_rng, 0.5)

	if hatchling_type_is_lesser:
		var hatchling_health = caster_health * LESSER_HATCHLING_HEALTH

		for i in range(0, LESSER_HATCHLING_COUNT):
			var hatchling: Creep = caster_scene.instantiate()
			hatchling.set_properties(caster_path, player, caster_size, caster_armor_type, caster_race, hatchling_health, caster_armor, caster_level)

			var random_offset: Vector2 = Vector2(Globals.synced_rng.randf_range(-1, 1) * LESSER_HATCHLING_RANDOM_OFFSET, Globals.synced_rng.randf_range(-1, 1) * LESSER_HATCHLING_RANDOM_OFFSET)
			var hatchling_pos: Vector2 = caster_pos + random_offset
			hatchling.set_position_wc3_2d(hatchling_pos)
			
			hatchling.set_portal_damage_multiplier(LESSER_HATCHLING_HEALTH)
			hatchling._current_path_index = caster_path_index

			Utils.add_object_to_world(hatchling)
			
			hatchling.set_unit_scale(LESSER_HATCHLING_SCALE)
	else:
		var hatchling_health = caster_health * GREATER_HATCHLING_HEALTH

		var hatchling: Creep = caster_scene.instantiate()
		hatchling.set_properties(caster_path, player, caster_size, caster_armor_type, caster_race, hatchling_health, caster_armor, caster_level)

		var hatchling_pos: Vector2 = caster_pos
		hatchling.set_position_wc3_2d(hatchling_pos)
		hatchling.set_portal_damage_multiplier(GREATER_HATCHLING_HEALTH)
		hatchling._current_path_index = caster_path_index

		Utils.add_object_to_world(hatchling)

		hatchling.set_unit_scale(GREATER_HATCHLING_SCALE)
