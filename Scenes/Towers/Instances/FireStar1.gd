extends Tower


var cedi_firestar_burn_bt: BuffType
var firestar_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Burn![/color]\n"
	text += "When this tower damages a creep it will ignite and take the towers damage as attack damage every 2 seconds. The buff slows movement speed by 5%, lasts 2.5 seconds and stacks. Each stack increases the damage by 5% and the slow by 1%.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+4% initial damage\n"
	text += "+0.2% damage per stack\n"
	text += " \n"

	text += "[color=GOLD]Double the Trouble[/color]\n"
	text += "When this tower damages a creep it has a 12.5% chance to launch an additional projectile that deals the same damage as a normal attack.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Burn![/color]\n"
	text += "When this tower damages a creep it will ignite it.\n"
	text += " \n"

	text += "[color=GOLD]Double the Trouble[/color]\n"
	text += "Chance to launch an additional projectile.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	set_target_count(14)


func tower_init():
	cedi_firestar_burn_bt = BuffType.new("cedi_firestar_burn_bt", 2.5, 0, false, self)
	var cedi_firestar_burn_bt_mod: Modifier = Modifier.new()
	cedi_firestar_burn_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.05, -0.01)
	cedi_firestar_burn_bt.set_buff_modifier(cedi_firestar_burn_bt_mod)
	cedi_firestar_burn_bt.set_buff_icon("@@1@@")
	cedi_firestar_burn_bt.set_buff_tooltip("Ingite\nThis is Ignited; it will take periodic damage and has reduced movement speed.")
	cedi_firestar_burn_bt.add_event_on_refresh(cedi_firestar_burn_bt_on_refresh)
	cedi_firestar_burn_bt.add_periodic_event(cedi_firestar_burn_bt_periodic, 2.0)

	firestar_pt = ProjectileType.create("LordofFlameMissile.mdl", 7.0, 1000, self)
	firestar_pt.enable_homing(firestar_pt_on_hit, 0)


func on_damage(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var target: Unit = event.get_target()
	var buff: Buff = target.get_buff_of_type(cedi_firestar_burn_bt)
	var buff_power: int = 0

	if buff != null:
		buff_power = buff.get_power() + 1
		buff = cedi_firestar_burn_bt.apply_custom_power(tower, target, 1, buff_power)
	else:
		buff_power = 0
		buff = cedi_firestar_burn_bt.apply_custom_power(tower, target, 1, buff_power)
		var damage_multiplier: float = 1.0 + 0.04 * level
		buff.user_real = damage_multiplier

	var double_trouble_chance: float = 0.125 + 0.005 * level

	if !tower.calc_chance(double_trouble_chance):
		return

	CombatLog.log_ability(tower, target, "Double the Trouble")

	Projectile.create_from_unit_to_unit(firestar_pt, tower, 1.0, 1.0, tower, target, true, false, false)


func firestar_pt_on_hit(p: Projectile, target: Unit):
	if target == null:
		return

	var tower: Tower = p.get_caster()
	var level: int = tower.get_level()
	var buff: Buff = target.get_buff_of_type(cedi_firestar_burn_bt)
	var buff_power: int = 0

	if buff != null:
		buff_power = buff.get_power() + 1
		buff = cedi_firestar_burn_bt.apply_custom_power(tower, target, 1, buff_power)
	else:
		buff_power = 0
		buff = cedi_firestar_burn_bt.apply_custom_power(tower, target, 1, buff_power)
		var damage_multiplier: float = 1.0 + 0.04 * level
		buff.user_real = damage_multiplier

	tower.do_attack_damage(target, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit_no_bonus())


func cedi_firestar_burn_bt_on_refresh(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Unit = buff.get_caster()
	var level: int = caster.get_level()
	var damage_multiplier_bonus: float = 0.05 + 0.002 * level

	buff.user_real += damage_multiplier_bonus


func cedi_firestar_burn_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var tower: Tower = buff.get_caster()
	var creep: Unit = buff.get_buffed_unit()
	var damage_multiplier: float = buff.user_real

	tower.do_attack_damage(creep, tower.get_current_attack_damage_with_bonus() * damage_multiplier, tower.calc_attack_multicrit_no_bonus())
