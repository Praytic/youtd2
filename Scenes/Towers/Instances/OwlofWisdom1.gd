extends Tower


var tomy_owl_pt: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {dmg_ratio_for_immune = 0.10, dmg_ratio_for_immune_add = 0.004, periodic_event_period = 5.0, energyball_chance = 0.25, energyball_radius_add = 1, energyball_dmg_base = 4500, energyball_dmg_exp_scale = 2.25},
		2: {dmg_ratio_for_immune = 0.15, dmg_ratio_for_immune_add = 0.006, periodic_event_period = 4.0, energyball_chance = 0.30, energyball_radius_add = 2, energyball_dmg_base = 6500, energyball_dmg_exp_scale = 3.25},
	}


func get_ability_description() -> String:
	var dmg_ratio_for_immune: String = Utils.format_percent(_stats.dmg_ratio_for_immune, 2)
	var dmg_ratio_for_immune_add: String = Utils.format_percent(_stats.dmg_ratio_for_immune_add, 2)
	var periodic_event_period: String = Utils.format_float(_stats.periodic_event_period, 2)
	var energyball_chance: String = Utils.format_percent(_stats.energyball_chance, 2)
	var energyball_radius_add: String = Utils.format_float(_stats.energyball_radius_add, 2)
	var energyball_dmg_base: String = Utils.format_float(_stats.energyball_dmg_base, 2)
	var energyball_dmg_exp_scale: String = Utils.format_float(_stats.energyball_dmg_exp_scale, 2)

	var text: String = ""

	text += "[color=GOLD]Weak Spots[/color]\n"
	text += "The Owl of Wisdom is able to find weak spots even on magic immune units. It's Energyball deals %s of its spell damage as energy damage to immune units.\n" % dmg_ratio_for_immune
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % dmg_ratio_for_immune_add
	text += " \n"

	text += "[color=GOLD]Energyball[/color]\n"
	text += "The Owl of Wisdom has a %s chance on attack to cast Energyball on the attacked creep. The Energyball deals %s + [%sx Towerexp] spell damage in a 100 AoE around the attacked creep. The experience bonus cannot exceed [150x current wave] damage.\b" % [energyball_chance, energyball_dmg_base, energyball_dmg_exp_scale]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s AoE range\n" % energyball_radius_add
	text += "+0.4% chance\n"
	text += " \n"

	text += "[color=GOLD]Energy Detection[/color]\n"
	text += "Every %s seconds, for each creep in 900 range the Owl of Wisdom has a 10%% chance to cast Energyball on it.\n" % periodic_event_period
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Weak Spots[/color]\n"
	text += "The Owl of Wisdom is able to find weak spots even on magic immune units.\n"
	text += " \n"

	text += "[color=GOLD]Energyball[/color]\n"
	text += "The Owl of Wisdom has a chance on attack to cast Energyball on the attacked creep. Energyball damage's scales with tower's experience.\b"
	text += " \n"

	text += "[color=GOLD]Energy Detection[/color]\n"
	text += "The Owl of Wisdom sometimes randomly casts Energyball.\n"
	text += " \n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_periodic_event(periodic, _stats.periodic_event_period)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_SPELL_CRIT_CHANCE, 0.05, 0.0015)
	modifier.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.0, 0.01)


func tower_init():
	tomy_owl_pt = ProjectileType.create("DarkSummonMissile.mdl", 5.0, 950.0, self)
	tomy_owl_pt.enable_homing(tomy_owl_pt_on_hit, 0)


func on_attack(event: Event):
	var tower: Tower = self
	var target: Creep = event.get_target()
	var chance: float = 0.25 + 0.004 * tower.get_level()

	if !tower.calc_chance(chance):
		return

	tomy_energyball_start(target)


func on_create(_preceding: Tower):
	var tower: Tower = self
	tower.user_int = 1


func periodic(_event: Event):
	var tower: Tower = self
	var chance: float = 0.10 + 0.002 * tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 900)

	while true:
		var target: Creep = it.next()

		if target == null:
			break

		if tower.calc_chance(chance):
			tomy_energyball_start(target)


func tomy_energyball_start(target: Creep):
	var tower: Tower = self
	Projectile.create_from_unit_to_unit(tomy_owl_pt, tower, 0, 0, tower, target, true, false, false)


func tomy_owl_pt_on_hit(projectile: Projectile, target: Unit):
	var tower: Tower = self

	var aoe_range: float = 100 + 1 * tower.get_level()

	var damage: float = _stats.energyball_dmg_base + min(_stats.energyball_dmg_exp_scale * tower.get_exp(), 150.0 * tower.get_player().get_level())
	var immune_damage_ratio: float = _stats.dmg_ratio_for_immune + _stats.dmg_ratio_for_immune_add * tower.get_level()
	var aoe_damage: float
	if !target.is_immune():
		aoe_damage = damage
	else:
		aoe_damage = damage * immune_damage_ratio * tower.get_prop_spell_damage_dealt()
	
	tower.do_spell_damage_aoe_unit(target, aoe_range, aoe_damage, tower.calc_spell_crit_no_bonus(), 0)

	var effect: int = Effect.create_colored("WispExplode.mdl", projectile.get_x(), projectile.get_y(), 0.0, 0, 0.7, Color.BLUE)
	Effect.set_lifetime(effect, 1.0)
