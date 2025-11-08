class_name CreepNecromancer extends BuffType


# NOTE: [ORIGINAL_GAME_DEVIATION] in original game,
# Necromancers raise skeletons. Don't have sprites for
# skeletons so raising creeps using their original sprites.

# NOTE: [ORIGINAL_GAME_DEVIATION] original script
# appears to set health of revived creep to double of the
# original amount. Not sure if this is correct? Left at 100%
# of original health for now.

# NOTE: this special is not affected by silence, on purpose.
# This is how it was in the original game.


const RAISE_DELAY: float = 2
const RAISE_MANA_COST: float = 10


var necromancer_aura_bt: BuffType


func _init(parent: Node):
	super("creep_necromancer", 0, 0, true, parent)

	necromancer_aura_bt = BuffType.create_aura_effect_type("necromancer_aura_bt", true, self)
	necromancer_aura_bt.set_hidden()
	necromancer_aura_bt.add_event_on_death(necromancer_aura_bt_on_death)

	add_aura(106, self)


func necromancer_aura_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var original_creep: Creep = buff.get_buffed_unit()
	var creep_size: CreepSize.enm = original_creep.get_size()
	var creep_is_lesser_size: bool = creep_size == CreepSize.enm.MASS || creep_size == CreepSize.enm.NORMAL

	if !creep_is_lesser_size:
		return

# 	NOTE: need to save all creep properties now before creep
# 	is destroyed
	var creep_uid: int = original_creep.get_uid()
	var creep_pos: Vector2 = original_creep.get_position_wc3_2d()
	var creep_scene_path: String = original_creep.get_scene_file_path()
	var creep_path: Path2D = original_creep.get_move_path()
	var player: Player = original_creep.get_player()
	var creep_armor_type: ArmorType.enm = original_creep.get_armor_type()
	var creep_race: CreepCategory.enm = original_creep.get_category()
	var creep_health: float = original_creep.get_overall_health()
	var creep_armor: float = original_creep.get_base_armor()
	var creep_level: int = original_creep.get_spawn_level()
	var creep_path_index: int = original_creep._current_path_index
	
	var necromancer: Creep = buff.get_caster()

	await Utils.create_manual_timer(RAISE_DELAY, self).timeout

	if !Utils.unit_is_valid(necromancer):
		return

	var necromancer_has_enough_mana: bool = necromancer.get_mana() >= RAISE_MANA_COST

	if !necromancer_has_enough_mana:
		return

	necromancer.subtract_mana(RAISE_MANA_COST, false)
	
	var it: Iterate = Iterate.over_units_in_range_of(null, TargetType.new(TargetType.CORPSES), creep_pos, 1000)

	var corpse_for_creep: CreepCorpse = null

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		var corpse: CreepCorpse = next as CreepCorpse

		if corpse == null:
			continue

		var corpse_match: bool = corpse.get_creep_uid() == creep_uid

		if corpse_match:
			corpse_for_creep = corpse

			break

	if corpse_for_creep == null:
		return

# 	NOTE: creep specials are not carried over on purpose
	var creep_scene: PackedScene = load(creep_scene_path)
	var raised_creep: Creep = creep_scene.instantiate()
	raised_creep.set_properties(creep_path, player, creep_size, creep_armor_type, creep_race, creep_health, creep_armor, creep_level)

	raised_creep.set_position_wc3_2d(creep_pos)
	raised_creep._current_path_index = creep_path_index

	raised_creep.set_portal_damage_multiplier(0.5)

	Utils.add_object_to_world(raised_creep)

	var necromancer_pos: Vector2 = necromancer.get_position_wc3_2d()
	var effect_on_necromancer: int = Effect.create_simple("res://src/effects/upgrade_tower.tscn", necromancer_pos)
	Effect.set_color(effect_on_necromancer, Color.PURPLE)
	Effect.set_z_index(effect_on_necromancer, Effect.Z_INDEX_BELOW_CREEPS)
	var effect_on_raised_creep: int = Effect.create_simple("res://src/effects/freezing_breath_purple.tscn", creep_pos)
	Effect.set_z_index(effect_on_raised_creep, Effect.Z_INDEX_BELOW_CREEPS)

	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, necromancer, raised_creep)
	lightning.modulate = Color.PURPLE
	lightning.set_lifetime(0.5)

	corpse_for_creep.remove_from_game()
