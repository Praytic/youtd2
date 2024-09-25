extends TowerBehavior


var energetic_weapon_pt: ProjectileType
var absorb_target_bt: BuffType
var absorb_caster_bt: BuffType
var slow_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_mana_add = 50, mod_mana_regen_add = 1, projectile_damage = 500, projectile_damage_add = 25},
		2: {mod_mana_add = 100, mod_mana_regen_add = 3, projectile_damage = 1000, projectile_damage_add = 50},
	}



func get_ability_info_list() -> Array[AbilityInfo]:
	var projectile_damage: String = Utils.format_float(_stats.projectile_damage, 2)
	var projectile_damage_add: String = Utils.format_float(_stats.projectile_damage_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Energetic Weapon"
	ability.icon = "res://resources/icons/rockets/rocket_03.tres"
	ability.description_short = "The Accelerator attacks with energetic missiles, which deal AoE spell damage scaled with tower's current mana. Additionally, the missile slows hit creeps.\n"
	ability.description_full = "The Accelerator attacks with energetic missiles, which deal %s plus 3 times the current mana as spell damage to all units in 250 range of the missile. Additionally, the missile slows all units by 1%% for each 4000 damage it deals to a creep for 1.5 seconds. Cannot slow by more than 20%%. Each attack consumes 20%% of this tower's current mana.\n" % projectile_damage \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s spell damage\n" % projectile_damage_add \
	+ "+5% mana converted to damage\n" \
	+ "+0.04 seconds slow duration\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0, _stats.mod_mana_add)
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0, _stats.mod_mana_regen_add)


func tower_init():
	absorb_target_bt = BuffType.new("absorb_target_bt", 8, 0, false, self)
	absorb_target_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	absorb_target_bt.set_buff_tooltip("Energy Absorb Negative\nDecreases attack speed.")
	var absorb_target_bt_mod: Modifier = Modifier.new()
	absorb_target_bt_mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.1, 0.001)
	absorb_target_bt.set_buff_modifier(absorb_target_bt_mod)

	absorb_caster_bt = BuffType.new("absorb_caster_bt", 8, 0, true, self)
	absorb_caster_bt.set_buff_icon("res://resources/icons/generic_icons/angel_wings.tres")
	absorb_caster_bt.set_buff_tooltip("Energy Absorb Positive\nIncreases mana regeneration.")
	var absorb_caster_bt_mod: Modifier = Modifier.new()
	absorb_caster_bt_mod.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.04)
	absorb_caster_bt.set_buff_modifier(absorb_caster_bt_mod)

	energetic_weapon_pt = ProjectileType.create_ranged("path_to_projectile_sprite", 1000, 650, self)
	energetic_weapon_pt.enable_collision(energetic_weapon_pt_on_hit, 250, TargetType.new(TargetType.CREEPS), false)

	slow_bt = BuffType.new("slow_bt", 1.5, 0.04, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Slowed\nReduces movement speed.")
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	slow_bt.set_buff_modifier(slow_bt_mod)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	autocast.title = "Energy Absorb"
	autocast.icon = "res://resources/icons/rings/ring_06.tres"
	autocast.description_short = "Decreases attack speed of all towers in range. Increases mana regeneration of the Accelerator.\n"
	autocast.description = "Decreases the attack speed of all towers in 1000 range by 10%. Increases the mana regeneration of the Accelerator by 2 mana per second for each weakened tower. Both effects last 8 seconds\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-0.1% attack speed weakening\n" \
	+ "+0.04 mana per second\n"

	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 40
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.buff_target_type = null
	autocast.handler = on_autocast

	return [autocast]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var angle: float = atan2(target.get_y() - tower.get_y(), target.get_x() - tower.get_x())
	var mana: float = tower.get_mana()

	var p: Projectile = Projectile.create(energetic_weapon_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), Vector3(tower.get_x() + cos(angle) * 110, tower.get_y() + sin(angle) * 110, tower.get_z()), rad_to_deg(angle))
	var damage_from_mana: float = mana * (3.0 + 0.05 * tower.get_level())
	var projectile_damage: float = _stats.projectile_damage + _stats.projectile_damage_add * tower.get_level() + damage_from_mana
	p.user_real = projectile_damage
	p.set_projectile_scale(2.0)

	tower.set_mana(mana * 0.8)


func on_autocast(_event: Event):
	var lvl: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 1000)
	var tower_count: int = 0

	while true:
		var target: Unit = it.next()

		if target == null:
			break

		if target != tower:
			tower_count += 1
			absorb_target_bt.apply(tower, target, lvl)

	if tower_count > 0:
		var buff_level: int = (50 + lvl) * tower_count
		absorb_caster_bt.apply(tower, tower, buff_level)


func energetic_weapon_pt_on_hit(projectile: Projectile, target: Unit):
	var caster: Unit = projectile.get_caster()
	var lightning_start_pos: Vector3 = Vector3(
		projectile.get_x() + 50.0 * cos(deg_to_rad(projectile.get_direction())),
		projectile.get_y() + 50.0 * sin(deg_to_rad(projectile.get_direction())),
		60.0
		)
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, lightning_start_pos, target)
	interpolated_sprite.set_lifetime(0.2)

	var projectile_damage: float = projectile.user_real
	projectile.do_spell_damage(target, projectile_damage)

	var slow: float = projectile_damage / 4000
	if slow > 20:
		slow = 20
	var slow_buff_level: int = int(slow * 10)
	var slow_buff_duration: float = 1.5 + 0.04 * caster.get_level()
	slow_bt.apply_custom_timed(caster, target, slow_buff_level, slow_buff_duration)

	SFX.sfx_at_unit(SfxPaths.ELECTRIC_SPRING, target)
