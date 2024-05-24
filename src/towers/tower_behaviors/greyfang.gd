extends TowerBehavior


var shard_pt: ProjectileType

const BONE_SHATTER_DAMAGE_RATIO: float = 0.25
const SHARD_SPREAD_RADIUS: float = 300


func get_ability_info_list() -> Array[AbilityInfo]:
	var bone_shatter_damage_ratio: String = Utils.format_percent(BONE_SHATTER_DAMAGE_RATIO, 2)

	var list: Array[AbilityInfo] = []
	
	var dire_instinct: AbilityInfo = AbilityInfo.new()
	dire_instinct.name = "Dire Instinct"
	dire_instinct.icon = "res://resources/icons/shields/shield_wood_small_glowing.tres"
	dire_instinct.description_short = "This tower has extra luck with multicrit compared to other towers. This ability affects only normal attacks.\n"
	dire_instinct.description_full = "This tower has extra luck with multicrit compared to other towers. This ability affects only normal attacks.\n" \
	+ " \n" \
	+ "[color=ORANGE]Details:[/color]\n" \
	+ "This tower overrides normal logic for calculating attack criticals. It rolls for every multicrit even if an earlier one fails. In addition, multicrit chance reduction occurs only on successful critical rolls. At starting stats, this tower is more likely to get crits than non-crits!\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "At level 25, rolls again for failed multicrits, which boosts multicrits even further.\n" \
	+ ""
	list.append(dire_instinct)

	var bone_shatter: AbilityInfo = AbilityInfo.new()
	bone_shatter.name = "Bone Shatter"
	bone_shatter.icon = "res://resources/icons/swords/greatsword_01.tres"
	bone_shatter.description_short = "Creeps killed by this tower release a number of spiky shards in random directions that deal attack damage.\n"
	bone_shatter.description_full = "Creeps killed by this tower release a number of spiky shards in random directions that deal %s of this tower's attack damage to creeps they hit.\n" % bone_shatter_damage_ratio \
	+ " \n" \
	+ "The number of shards is equivalent to this tower's multicrit count.\n" \
	+ " \n" \
	+ "One shard can hit multiple creeps but will lose a fifth of its current damage after each hit.\n" \
	+ ""
	list.append(bone_shatter)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_kill(on_kill)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.20, 0.004)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 2.0, 0.04)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2.0, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.022)


func tower_init():
	shard_pt = ProjectileType.create_interpolate("ThornyShieldTargetChestLeft.mdl", 5000, self)
	shard_pt.enable_collision(shard_pt_on_collide, 40, TargetType.new(TargetType.CREEPS), false)


func on_attack(_event: Event):
#	Remove normal critical ((also, sadly, this removes any
#	bonus crits which were added by other callbacks before
#	this one))
	tower.reset_attack_crits()

	var do_two_rolls: bool = tower.get_level() == 25

	var remaining_count: int = tower.get_prop_multicrit_count()
	var current_chance: float = tower.get_prop_atk_crit_chance()

	var crit_count: int = 0
	while true:
		if remaining_count <= 0:
			break

		remaining_count -= 1

		var first_roll: bool = Utils.rand_chance(Globals.synced_rng, min(current_chance, Constants.ATK_CRIT_CHANCE_CAP))

		if first_roll:
			crit_count += 1
			current_chance *= Constants.ATK_MULTICRIT_DIMISHING
		elif do_two_rolls:
			var second_roll: bool = Utils.rand_chance(Globals.synced_rng, min(current_chance, Constants.ATK_CRIT_CHANCE_CAP))

			if second_roll:
				crit_count += 1
				current_chance *= Constants.ATK_MULTICRIT_DIMISHING

	var crit_damage: float = tower._calc_attack_multicrit_from_crit_count(crit_count, 0)
	tower._current_crit_count = crit_count
	tower._current_crit_damage = crit_damage


func on_kill(event: Event):
	var creep: Unit = event.get_target()
	var shard_count: int = tower.get_prop_multicrit_count()
	var first_angle: float = deg_to_rad(Globals.synced_rng.randf_range(0, 180))
	var angle_between: float = deg_to_rad(180 / shard_count * 2)
	var shard_start_pos: Vector3 = Vector3(creep.get_x(), creep.get_y(), 0)

	for i in range(0, shard_count):
		var shard_angle: float = first_angle + angle_between * i
		var offset: Vector2 = Vector2(SHARD_SPREAD_RADIUS, 0).rotated(shard_angle)
		var shard_end_pos: Vector3 = shard_start_pos + Vector3(offset.x, offset.y, 0)

		var p: Projectile = Projectile.create_linear_interpolation_from_point_to_point(shard_pt, tower, 1, 1, shard_start_pos, shard_end_pos, 0)
		p.set_projectile_scale(0.25)
		p.set_color(Color.GRAY)

		p.user_real = BONE_SHATTER_DAMAGE_RATIO


func shard_pt_on_collide(p: Projectile, target: Unit):
	if target == null:
		return

	var current_shard_damage_ratio: float = p.user_real

	var shard_damage: float = current_shard_damage_ratio * tower.get_current_attack_damage_with_bonus()
	tower.do_attack_damage(target, shard_damage, tower.calc_attack_multicrit_no_bonus())

	var new_shard_damage_ratio: float = current_shard_damage_ratio * 0.8
	p.user_real = new_shard_damage_ratio
