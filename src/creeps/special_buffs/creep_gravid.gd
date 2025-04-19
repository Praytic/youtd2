class_name CreepGravid extends BuffType


const MATURED_TIME_MAX: float = 12
const SCALE_MIN: float = 0.4
const SCALE_MAX: float = 1.0
const CHILD_POS_RAND_OFFSET: float = 30

const CHILD_COUNT_WEIGHTS: Dictionary = {
	2: 1.0,
	3: 1.0,
	4: 1.0,
	5: 0.2,
}


func _init(parent: Node):
	super("creep_gravid", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(ModificationType.enm.MOD_BOUNTY_GRANTED, -0.75, 0.0)
	modifier.add_modification(ModificationType.enm.MOD_EXP_GRANTED, -0.75, 0.0)
	modifier.add_modification(ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH, -0.75, 0.0)
	set_buff_modifier(modifier)

	add_event_on_create(on_create)
	add_periodic_event(periodic, 0.5)
	add_event_on_death(on_death)


# The first creep starts as "matured"
func on_create(event: Event):
	var buff: Buff = event.get_buff()
	buff.user_real = MATURED_TIME_MAX


func periodic(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var maturing_timer: float = buff.user_real
	maturing_timer += 0.5
	buff.user_real = maturing_timer

	update_creep_scale(creep, maturing_timer)


# NOTE: limit to 2 children for champions because there are
# many champions per wave. Otherwise, champions could spawn
# too many children which would make a wave unreasonably
# difficult.
func on_death(event: Event):
	var buff: Buff = event.get_buff()
	var adult: Creep = buff.get_buffed_unit()
	var adult_maturing_timer: float = buff.user_real
	var adult_is_matured: bool = adult_maturing_timer >= MATURED_TIME_MAX

	if !adult_is_matured:
		return

	var child_count: int
	var adult_size: CreepSize.enm = adult.get_size()
	var adult_is_champion: bool = adult_size == CreepSize.enm.CHAMPION
	if adult_is_champion:
		child_count = 2
	else:
		child_count = Utils.random_weighted_pick(Globals.synced_rng, CHILD_COUNT_WEIGHTS)

	var adult_pos: Vector2 = adult.get_position_wc3_2d()
	var adult_scene_path: String = adult.get_scene_file_path()
	var adult_path: Path2D = adult.get_move_path()
	var player: Player = adult.get_player()
	var adult_armor_type: ArmorType.enm = adult.get_armor_type()
	var adult_race: CreepCategory.enm = adult.get_category()
	var child_health: float = adult.get_overall_health() / child_count * 1.2
	var adult_armor: float = adult.get_base_armor()
	var adult_level: int = adult.get_spawn_level()
	var adult_path_index: int = adult._current_path_index

	var creep_scene: PackedScene = load(adult_scene_path)
	var child_mana: float = adult.get_overall_mana() / child_count
	var adult_specials: Array[int] = adult.get_special_list()
	var adult_facing: float = adult.get_unit_facing()
	var child_pos_path_offset: float = Globals.synced_rng.randf_range(50, 150)
	var adult_move_vector: Vector2 = Vector2(child_pos_path_offset, 0).rotated(deg_to_rad(adult_facing))

	var child_portal_damage_multiplier: float = 1.0 / child_count / 2

	for i in range(0, child_count):
		var child_creep: Creep = creep_scene.instantiate()
		child_creep.set_properties(adult_path, player, adult_size, adult_armor_type, adult_race, child_health, adult_armor, adult_level)

		var random_offset: Vector2 = Vector2(Globals.synced_rng.randf_range(-1, 1) * CHILD_POS_RAND_OFFSET, Globals.synced_rng.randf_range(-1, 1) * CHILD_POS_RAND_OFFSET)
		var offset_on_path: Vector2 = i * adult_move_vector.rotated(deg_to_rad(180))
		var child_pos: Vector2 = adult_pos + random_offset + offset_on_path
		
		child_creep.set_base_mana(child_mana)
		child_creep.set_mana(child_mana)
		child_creep.set_position_wc3_2d(child_pos)
		child_creep._current_path_index = adult_path_index

		child_creep.set_portal_damage_multiplier(child_portal_damage_multiplier)

		Utils.add_object_to_world(child_creep)

		WaveSpecial.apply_to_creep(adult_specials, child_creep)

		var child_gravid_buff: Buff = child_creep.get_buff_of_type(self)

		if child_gravid_buff == null:
			push_error("Child gravid buff is somehow null")

			return

#		NOTE: set mature timer to 0. Note that this
#		overwrites the initial value set in on_create()
		var maturing_timer: float = 0
		child_gravid_buff.user_real = maturing_timer
		update_creep_scale(child_creep, maturing_timer)


func update_creep_scale(creep: Creep, maturing_timer: float):
	var creep_is_matured: bool = maturing_timer >= MATURED_TIME_MAX

	if creep_is_matured:
		return

	var creep_scale: float = SCALE_MIN + maturing_timer / MATURED_TIME_MAX * (SCALE_MAX - SCALE_MIN)
	creep.set_unit_scale(creep_scale)
