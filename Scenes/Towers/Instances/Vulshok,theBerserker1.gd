extends Tower


# NOTE: this is the fizzbuzz tower


var boekie_vulshok_slow_bt: BuffType
var multiboard: MultiboardValues


var attack_count: int = 0
var do_splash_next: bool = false
var growth_count: int = 0


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Ultimate Fighter[/color]\n"
	text += "Vulshok uses his great power to specialize his attacks:\n"
	text += "- Every 3rd attack adds a critical hit\n"
	text += "- Every 7th attack deals 3000 bonus attackdamage\n"
	text += "- Every 12th attack splashes all damage over 200 AoE\n"
	text += "- Every 15th attack adds 0.5% attack damage permanently\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+200 attackdamage on 7th attack\n"
	text += " \n"

	text += "[color=GOLD]Ultimate Fighter[/color]\n"
	text += "When Vulshok damages a creep it gets maimed. The creep is slowed by 10% for 5 seconds and every second it gets slowed by an extra 5%. This buff lasts for 5 seconds and cannot be refreshed.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% slow \n"
	text += "+0.1% extra slow per second\n"
	
	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Ultimate Fighter[/color]\n"
	text += "Vulshok uses his great power to specialize his attacks. Attacks will sometimes deal bonus damage, AoE damage or empower Vulshok.\n"
	text += " \n"

	text += "[color=GOLD]Ultimate Fighter[/color]\n"
	text += "When Vulshok damages a creep it gets maimed.\n"
	
	return text

func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 2.0 - Constants.INNATE_MOD_ATK_CRIT_DAMAGE, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.03)


func tower_init():
	multiboard = MultiboardValues.new(4)
	multiboard.set_key(0, "Attacks to crit")
	multiboard.set_key(1, "Attacks to damage")
	multiboard.set_key(2, "Attacks to splash")
	multiboard.set_key(3, "Attacks to grow")

	boekie_vulshok_slow_bt = BuffType.new("boekie_vulshok_slow_bt", 5, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.10, -0.001)
	boekie_vulshok_slow_bt.set_buff_modifier(mod)
	boekie_vulshok_slow_bt.set_buff_icon("@@0@@")
	boekie_vulshok_slow_bt.set_buff_tooltip("Maimed\nThis creep is maimed; it has reduced movement speed.")
	boekie_vulshok_slow_bt.add_periodic_event(boekie_vulshok_slow_bt_periodic, 1.0)


func on_attack(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var crit: int = 0

	attack_count += 1

#	Crit (every 3rd)
	if attack_count % 3 == 0:
		tower.add_attack_crit()
#		So the triggered attackdamage can crit too!
		crit = 1

#	Bonus damage (every 7th)
	if attack_count % 7 == 0:
#		Splashed bonus damage (every 84th)
		if attack_count % 12 == 0:
			tower.do_attack_damage_aoe_unit(target, 200, 3000 + 200 * level, tower.calc_attack_multicrit(0, 0, crit), 0)
			var effect: int = Effect.create_scaled("DoomDeath.mdl", target.get_visual_x(), target.get_visual_y(), 0, 0, 1.5)
			Effect.destroy_effect_after_its_over(effect)
		else:
			tower.do_attack_damage(target, 3000 + 200 * level, tower.calc_attack_multicrit(0, 0, crit), 0)
			var effect: int = Effect.create_scaled("DoomDeath.mdl", target.get_visual_x(), target.get_visual_y(), 0, 0, 0.2)
			Effect.destroy_effect_after_its_over(effect)

#	Splash (every 12th)
	if attack_count % 12 == 0:
		do_splash_next = true

#	Growth (every 15th)
	if attack_count % 15 == 0:
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.005)

#		Rare text has increased chance to show with increased triggerchances. ;]
		var floating_text: String
		if tower.calc_chance(0.005):
			floating_text = "I WILL BATHE IN YOUR BLOOD!"
		elif tower.calc_chance(0.1):
			floating_text = "FEAR ME!"
		elif tower.calc_chance(0.4):
			floating_text = "GRRR!"
		else:
			floating_text = "ROAR!"

		tower.get_player().display_floating_text(floating_text, tower, 255, 100, 100)

#		Increase model size
#		TODO: set_unit_scale() is not implemented yet
		growth_count += 1
		# tower.set_unit_scale(0.9 + 0.001 * growth_count)

	if attack_count >= 420:
		attack_count = 0


func on_damage(event: Event):
	var tower: Tower = self
	var target: Creep = event.get_target()
	var level: int = tower.get_level()

	if do_splash_next:
		do_splash_next = false

#		+1 multicrit count for the guaranteed crit every three attacks
		tower.do_attack_damage_aoe_unit(target, 200, tower.get_current_attack_damage_with_bonus(), tower.calc_attack_multicrit(0, 0, 1), 0.0)

#		Cancel damage from regular attack
		event.damage = 0

#		Apply slow to all creeps hit
		var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), target, 200)
		
		while true:
			var creep: Creep = it.next()

			if creep == null:
				break

			if creep.get_buff_of_type(boekie_vulshok_slow_bt) == null:
				boekie_vulshok_slow_bt.apply(tower, creep, level * 5)
	else:
		if target.get_buff_of_type(boekie_vulshok_slow_bt) == null:
			boekie_vulshok_slow_bt.apply(tower, target, level * 5)


func on_tower_details() -> MultiboardValues:
	var attacks_to_crit: String = str(3 - attack_count % 3)
	var attacks_to_damage: String = str(7 - attack_count % 7)
	var attacks_to_splash: String = str(12 - attack_count % 12)
	var attacks_to_grow: String = str(15 - attack_count % 15)

	multiboard.set_value(0, attacks_to_crit)
	multiboard.set_value(1, attacks_to_damage)
	multiboard.set_value(2, attacks_to_splash)
	multiboard.set_value(3, attacks_to_grow)

	return multiboard


func boekie_vulshok_slow_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var new_power: int = int(buff.get_power() + 50 + 0.20 * buff.get_level())
	buff.set_power(new_power)
