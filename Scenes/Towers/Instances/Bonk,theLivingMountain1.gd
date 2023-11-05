extends Tower


var cb_stun: BuffType
var boekie_mountain_morale_bt: BuffType
var rock_pt: ProjectileType
var multiboard: MultiboardValues
var grow_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Grow![/color]\n"
	text += "Every 25 seconds Bonk grows, gaining 4 experience and 3% bonus attackdamage. Bonk can grow 160 times.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1% bonus attackdamage\n"
	text += " \n"

	text += "[color=GOLD]Landslide![/color]\n"
	text += "Bonk has a 25% chance on attack to throw rocks at all creeps in 300 AoE around the main target. These rocks deal 700 spelldamage and stun for 0.5 seconds. Landslide deals 15 bonus spelldamage per grow, but the ability only works once Bonk has grown at least 20 times.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+50 spelldamage\n"
	text += " \n"

	text += "[color=GOLD]Crush![/color]\n"
	text += "Whenever Bonk damages a stunned creep it deals 5000 spelldamage to it. When this happens, towers in 500 range will gain 10% attackspeed and damage for 10 seconds. Crush deals 50 bonus spelldamage per grow, but the ability only works once Bonk has grown at least 10 times.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+250 spelldamage\n"
	text += "+0.4% attackspeed and damage\n"
	text += " \n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Grow![/color]\n"
	text += "Bonk will periodically grow, gaining experience and bonus attackdamage.\n"
	text += " \n"

	text += "[color=GOLD]Landslide![/color]\n"
	text += "Bonk has a chance to throw rocks at creeps around the main target. These rocks deal spelldamage and stun.\n"
	text += " \n"

	text += "[color=GOLD]Crush![/color]\n"
	text += "Whenever Bonk damages a stunned creep it gives a morale boost to nearby towers.\n"
	text += " \n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 25)


func load_specials(modifier: Modifier):
	_set_attack_style_splash({100: 1.0})
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MASS, 0.25, 0.005)


func tower_init():
	cb_stun = CbStun.new("bonk_stun", 0, 0, false, self)
	
	boekie_mountain_morale_bt = BuffType.new("boekie_mountain_morale_bt", 10, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.004)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.10, 0.004)
	boekie_mountain_morale_bt.set_buff_modifier(mod)
	boekie_mountain_morale_bt.set_buff_icon("@@0@@")
	boekie_mountain_morale_bt.set_buff_tooltip("Morale Boost\nThis tower's morale was boosted; it will attack faster and deal extra damage.")

	rock_pt = ProjectileType.create("AncientProtectorMissile.mdl", 4, 700, self)
	rock_pt.enable_homing(rock_pt_on_hit, 0)

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Number of Grows")


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var chance: float = 0.25
	var enough_grow_count_for_landslide: bool = grow_count >= 20

	if !tower.calc_chance(chance):
		return

	if !enough_grow_count_for_landslide:
		return

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 300)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		Projectile.create_from_unit_to_unit(rock_pt, tower, 1.0, 0.0, tower, next, true, false, false)


func on_damage(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var crush_damage: float = 5000 + 250 * level + 50 * grow_count

	var enough_grow_count_for_crush: bool = grow_count >= 10
	if !enough_grow_count_for_crush:
		return

	if !creep.is_stunned():
		return

	tower.do_spell_damage(creep, crush_damage, tower.calc_spell_crit_no_bonus())
	var effect: int = Effect.create_scaled("ImpaleTargetDust.mdl", creep.get_x(), creep.get_y(), 0.0, 0, 2.0)
	Effect.set_lifetime(effect, 3.0)

	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.TOWERS), tower, 500)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		boekie_mountain_morale_bt.apply(tower, next, level)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, str(grow_count))

	return multiboard

func periodic(_event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var reached_max_growth: bool = grow_count >= 160

	if reached_max_growth:
		return

	var effect: int = Effect.create_scaled("EntanglingRootsTarget.mdl", tower.get_visual_x(), tower.get_visual_y(), 30.0, 0, 1.8)
	Effect.set_lifetime(effect, 1.0)

	tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.03 + 0.001 * level)
	tower.add_exp(4)

	grow_count += 1

	# TODO: Unit.setScale() is not implemented yet
	# tower.setScale(0.35 + grow_count * 0.0025)


func rock_pt_on_hit(projectile: Projectile, creep: Unit):
	var tower: Tower = projectile.get_caster()
	var damage: float = 700 + 50 * tower.get_level() + 15 * grow_count

	tower.do_spell_damage(creep, damage, tower.calc_spell_crit_no_bonus())
	cb_stun.apply_only_timed(tower, creep, 0.5)
