extends TowerBehavior


# NOTE: this is the fizzbuzz tower


var slow_bt: BuffType
var multiboard: MultiboardValues


var attack_count: int = 0
var do_splash_next: bool = false
var growth_count: int = 0


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ultimate_fighter: AbilityInfo = AbilityInfo.new()
	ultimate_fighter.name = "Ultimate Fighter"
	ultimate_fighter.icon = "res://resources/icons/weapons_misc/glaive_02.tres"
	ultimate_fighter.description_short = "Vulshok uses his great power to specialize his attacks. Attacks will sometimes deal bonus attack damage, AoE attack damage or empower Vulshok.\n"
	ultimate_fighter.description_full = "Vulshok uses his great power to specialize his attacks:\n" \
	+ "- Every 3rd attack adds a critical hit\n" \
	+ "- Every 7th attack deals 3000 bonus attack damage\n" \
	+ "- Every 12th attack splashes all damage over 200 AoE\n" \
	+ "- Every 15th attack adds 0.5% attack damage permanently\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+200 attack damage on 7th attack\n"
	list.append(ultimate_fighter)

	var maim: AbilityInfo = AbilityInfo.new()
	maim.name = "Maim"
	maim.icon = "res://resources/icons/clubs/club_glowing.tres"
	maim.description_short = "Slows hit creeps.\n"
	maim.description_full = "Slows hit creeps for 5 seconds. The slow amount starts at 10% and increases by 5% every second. This buff lasts for 5 seconds and cannot be refreshed.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.5% slow \n" \
	+ "+0.1% extra slow per second\n"
	list.append(maim)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# crit dmg = yes
# attack speed add = no
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.75, 0.0)
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.03)


func tower_init():
	multiboard = MultiboardValues.new(4)
	multiboard.set_key(0, "Attacks to crit")
	multiboard.set_key(1, "Attacks to damage")
	multiboard.set_key(2, "Attacks to splash")
	multiboard.set_key(3, "Attacks to grow")

	slow_bt = BuffType.new("slow_bt", 5, 0, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.10, -0.001)
	slow_bt.set_buff_modifier(mod)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip("Maim\nReduces movement speed.")
	slow_bt.add_periodic_event(slow_bt_periodic, 1.0)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var crit: int = 0

	attack_count += 1

#	Crit (every 3rd)
	if attack_count % 3 == 0:
		CombatLog.log_ability(tower, null, "Crit")
		tower.add_attack_crit()
#		So the triggered attack damage can crit too!
		crit = 1

#	Bonus damage (every 7th)
	if attack_count % 7 == 0:
		CombatLog.log_ability(tower, null, "Bonus Damage")
#		Splashed bonus damage (every 84th)
		if attack_count % 12 == 0:
			tower.do_attack_damage_aoe_unit(target, 200, 3000 + 200 * level, tower.calc_attack_multicrit(0, 0, crit), 0)
			var effect: int = Effect.create_scaled("DoomDeath.mdl", Vector3(target.get_x(), target.get_y(), 0), 0, 5)
			Effect.destroy_effect_after_its_over(effect)
		else:
			tower.do_attack_damage(target, 3000 + 200 * level, tower.calc_attack_multicrit(0, 0, crit), 0)
			var effect: int = Effect.create_scaled("DoomDeath.mdl", Vector3(target.get_x(), target.get_y(), 0), 0, 5)
			Effect.destroy_effect_after_its_over(effect)

#	Splash (every 12th)
	if attack_count % 12 == 0:
		CombatLog.log_ability(tower, null, "Splash")
		do_splash_next = true

#	Growth (every 15th)
	if attack_count % 15 == 0:
		CombatLog.log_ability(tower, null, "Growth")
		
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

		tower.get_player().display_floating_text(floating_text, tower, Color8(255, 100, 100))

#		Increase model size
		growth_count += 1
# 		NOTE: in original script, scale starts from 0.9.
# 		Changed to start from 1.0 because 0.9 value made
# 		scale jump from 1.0 to 0.9 after first change.
		var unit_scale: float = 1.0 + 0.001 * growth_count
		tower.set_unit_scale(unit_scale)

	if attack_count >= 420:
		attack_count = 0


func on_damage(event: Event):
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

			if creep.get_buff_of_type(slow_bt) == null:
				slow_bt.apply(tower, creep, level * 5)
	else:
		if target.get_buff_of_type(slow_bt) == null:
			slow_bt.apply(tower, target, level * 5)


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


func slow_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var new_power: int = int(buff.get_power() + 50 + 0.20 * buff.get_level())
	buff.set_power(new_power)
