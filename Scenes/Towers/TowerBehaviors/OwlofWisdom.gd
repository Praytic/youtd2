extends TowerBehavior


var missile_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_ratio_for_immune = 0.10, dmg_ratio_for_immune_add = 0.004, periodic_event_period = 5.0, energyball_chance = 0.25, energyball_radius_add = 1, energyball_dmg_base = 4500, energyball_dmg_exp_scale = 2.25},
		2: {dmg_ratio_for_immune = 0.15, dmg_ratio_for_immune_add = 0.006, periodic_event_period = 4.0, energyball_chance = 0.30, energyball_radius_add = 2, energyball_dmg_base = 6500, energyball_dmg_exp_scale = 3.25},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var dmg_ratio_for_immune: String = Utils.format_percent(_stats.dmg_ratio_for_immune, 2)
	var dmg_ratio_for_immune_add: String = Utils.format_percent(_stats.dmg_ratio_for_immune_add, 2)
	var periodic_event_period: String = Utils.format_float(_stats.periodic_event_period, 2)
	var energyball_chance: String = Utils.format_percent(_stats.energyball_chance, 2)
	var energyball_radius_add: String = Utils.format_float(_stats.energyball_radius_add, 2)
	var energyball_dmg_base: String = Utils.format_float(_stats.energyball_dmg_base, 2)
	var energyball_dmg_exp_scale: String = Utils.format_float(_stats.energyball_dmg_exp_scale, 2)
	var energy_string: String = AttackType.convert_to_colored_string(AttackType.enm.ENERGY)

	var list: Array[AbilityInfo] = []

	var energyball: AbilityInfo = AbilityInfo.new()
	energyball.name = "Energyball"
	energyball.icon = "res://Resources/Icons/TowerIcons/StormBattery.tres"
	energyball.description_short = "The Owl of Wisdom has a chance on attack to cast [color=GOLD]Energyball[/color] on the main target. [color=GOLD]Energyball[/color] deals AoE spell damage scales with tower's experience.\b"
	energyball.description_full = "The Owl of Wisdom has a %s chance on attack to cast [color=GOLD]Energyball[/color] on the main target. The [color=GOLD]Energyball[/color] deals [color=GOLD][%s + (%s x  tower exp)][/color] spell damage in a 100 AoE around the attacked creep. The experience bonus cannot exceed [color=GOLD][150x current wave][/color] damage.\n" % [energyball_chance, energyball_dmg_base, energyball_dmg_exp_scale] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s AoE range\n" % energyball_radius_add \
	+ "+0.4% chance\n"
	list.append(energyball)

	var weak_spots: AbilityInfo = AbilityInfo.new()
	weak_spots.name = "Weak Spots"
	weak_spots.icon = "res://Resources/Icons/orbs/orb_ice_melting.tres"
	weak_spots.description_short = "The Owl of Wisdom is able to find weak spots even on magic immune units.\n"
	weak_spots.description_full = "The Owl of Wisdom is able to find weak spots even on magic immune units. It's [color=GOLD]Energyball[/color] deals %s of its spell damage as %s damage to immune units.\n" % [dmg_ratio_for_immune, energy_string] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % dmg_ratio_for_immune_add
	list.append(weak_spots)

	var energy_detection: AbilityInfo = AbilityInfo.new()
	energy_detection.name = "Energy Detection"
	energy_detection.icon = "res://Resources/Icons/trinkets/trinket_10.tres"
	energy_detection.description_short = "The Owl of Wisdom sometimes randomly casts [color=GOLD]Energyball[/color].\n"
	energy_detection.description_full = "Every %s seconds, for each creep in 900 range the Owl of Wisdom has a 10%% chance to cast [color=GOLD]Energyball[/color] on it.\n" % periodic_event_period \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% chance\n"
	energy_detection.radius = 900
	energy_detection.target_type = TargetType.new(TargetType.CREEPS)
	list.append(energy_detection)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, _stats.periodic_event_period)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# spell crit chance = yes
# spell crit chance add = no
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.0375, 0.0015)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.01)


func tower_init():
	missile_pt = ProjectileType.create("DarkSummonMissile.mdl", 5.0, 950.0, self)
	missile_pt.enable_homing(missile_pt_on_hit, 0)


func on_attack(event: Event):
	var target: Creep = event.get_target()
	var chance: float = 0.25 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, target, "Energyball")

	tomy_energyball_start(target)


func on_create(_preceding: Tower):
	tower.user_int = 1


func periodic(_event: Event):
	var chance: float = 0.10 + 0.002 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

	while true:
		var target: Creep = it.next()

		if target == null:
			break

		if tower.calc_chance(chance):
			CombatLog.log_ability(tower, target, "Energy Detection")
			tomy_energyball_start(target)


func tomy_energyball_start(target: Creep):
	Projectile.create_from_unit_to_unit(missile_pt, tower, 0, 0, tower, target, true, false, false)


func missile_pt_on_hit(projectile: Projectile, target: Unit):
	if target == null:
		return

	var aoe_range: float = 100 + 1 * tower.get_level()

	var damage: float = _stats.energyball_dmg_base + min(_stats.energyball_dmg_exp_scale * tower.get_exp(), 150.0 * tower.get_player().get_team().get_level())
	var immune_damage_ratio: float = _stats.dmg_ratio_for_immune + _stats.dmg_ratio_for_immune_add * tower.get_level()
	var aoe_damage: float
	if !target.is_immune():
		aoe_damage = damage
	else:
		aoe_damage = damage * immune_damage_ratio * tower.get_prop_spell_damage_dealt()
	
	tower.do_spell_damage_aoe_unit(target, aoe_range, aoe_damage, tower.calc_spell_crit_no_bonus(), 0)

	var effect: int = Effect.create_colored("WispExplode.mdl", Vector3(projectile.get_x(), projectile.get_y(), 0.0), 0, 5, Color.BLUE)
	Effect.set_lifetime(effect, 1.0)
