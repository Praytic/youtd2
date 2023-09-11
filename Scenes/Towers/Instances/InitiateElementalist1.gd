extends Tower

# NOTE: too many differences between tiers. Had to make
# separate code paths for each tier.

# NOTE: original script has typos. Fixed them.
# 
# 1. 50 dmg for Frost Nova of 2nd tier. Fixed it to 250.
# 
# 2. Used aoe damage for "Aftershork" tier 3. Fixed to
#    single target damage.


var cb_stun: BuffType
var kel_slow: BuffType


func get_extra_tooltip_text() -> String:
	match get_tier():
		1: return get_extra_tooltip_text_1()
		2: return get_extra_tooltip_text_2()
		3: return get_extra_tooltip_text_3()
		4: return get_extra_tooltip_text_4()

	return ""


func get_extra_tooltip_text_1() -> String:
	var text: String = ""

	text += "[color=GOLD]Elemental Chaos[/color]\n"
	text += "Elementalist casts one of the following spells on attack:\n"
	text += " \n"
	text += "[color=ORANGE]Fire Blast:[/color] 66% chance, 200 AoE, 190 damage\n"
	text += "[color=ORANGE]Frost Nova:[/color] 33% chance, 250 AoE, 125 damage, 10% slow for 3 seconds\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+7.6 damage (Fire Blast)\n"
	text += "+5 damage (Frost Nova)\n"

	return text


func get_extra_tooltip_text_2() -> String:
	var text: String = ""

	text += "[color=GOLD]Elemental Chaos[/color]\n"
	text += "Elementalist casts one of the following spells on attack:\n"
	text += " \n"
	text += "[color=ORANGE]Fire Blast:[/color] 40% chance, 250 AoE, 500 damage\n"
	text += "[color=ORANGE]Frost Nova:[/color] 20% chance, 250 AoE, 250 damage, 12% slow for 3 seconds\n"
	text += "[color=ORANGE]Aftershock:[/color] 40% chance, 750 damage, 0.5 seconds stun\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+10 damage (Fire Blast)\n"
	text += "+8 damage (Frost Nova)\n"
	text += "+0.01 seconds stun (Aftershock)\n"

	return text


func get_extra_tooltip_text_3() -> String:
	var text: String = ""

	text += "[color=GOLD]Elemental Chaos[/color]\n"
	text += "Elementalist casts one of the following spells on attack:\n"
	text += " \n"
	text += "[color=ORANGE]Fire Blast:[/color] 30% chance, 250 AoE, 16500 damage\n"
	text += "[color=ORANGE]Frost Nova:[/color] 20% chance, 250 AoE, 800 damage, 14% slow for 4 seconds\n"
	text += "[color=ORANGE]Aftershock:[/color] 30% chance, 2000 damage, 0.5 seconds stun\n"
	text += "[color=ORANGE]Lightning Burst:[/color] 20% chance, 1650 damage, affects 5 random targets in 900 range \n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+18 damage (Fire Blast)\n"
	text += "+10 damage (Frost Nova)\n"
	text += "+0.01 seconds stun (Aftershock)\n"
	text += "+30 damage (Lightning Burst)\n"

	return text


func get_extra_tooltip_text_4() -> String:
	var text: String = ""

	text += "[color=GOLD]Elemental Fury[/color]\n"
	text += "Consecutive casts of the same spell will deal 50% more damage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% damage\n"
	text += " \n"
	text += "[color=GOLD]Elemental Chaos[/color]\n"
	text += "Elementalist casts one of the following spells on attack:\n"
	text += " \n"
	text += "[color=ORANGE]Fire Blast:[/color] 30% chance, 300 AoE, 3000 damage\n"
	text += "[color=ORANGE]Frost Nova:[/color] 20% chance, 300 AoE, 2000 damage, 15% slow for 4 seconds\n"
	text += "[color=ORANGE]Aftershock:[/color] 30% chance, 6000 damage, 0.7 seconds stun\n"
	text += "[color=ORANGE]Lightning Burst:[/color] 20% chance, 3000 damage, affects 6 random targets in 900 range\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+60 damage (Fire Blast)\n"
	text += "+80 damage (Frost Nova)\n"
	text += "+0.02 seconds stun (Aftershock)\n"
	text += "+60 damage (Lightning Burst)\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)


func tower_init():
	cb_stun = CbStun.new("initiate_elementalist_stun", 0, 0, false, self)

	var slow: Modifier = Modifier.new()
	slow.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	kel_slow = BuffType.new("kel_slow", 0, 0, false, self)
	kel_slow.set_buff_icon("@@0@@")
	kel_slow.set_buff_modifier(slow)
	kel_slow.set_buff_tooltip("Slow\nThis unit is Slowed; it has reduced movement speed.")


func on_attack(event: Event):
	match get_tier():
		1: return on_attack_1(event)
		2: return on_attack_2(event)
		3: return on_attack_3(event)
		4: return on_attack_4(event)

	return ""


func on_attack_1(event: Event):
	var tower: Tower = self
	var random_spell_id = randi_range(1, 3)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate

	if random_spell_id < 3:
		SFX.sfx_at_unit("FireLordDeathExplode.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 200, 190 + tower.get_level() * 7.6, tower.calc_spell_crit_no_bonus(), 0)
	else:
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 250)

		while true:
			u = it.next()

			if u == null:
				break

			kel_slow.apply_custom_timed(tower, u, 100, 3)

		SFX.sfx_at_unit("FrostNovaTarget.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 250, 125 + tower.get_level() * 5, tower.calc_spell_crit_no_bonus(), 0)
			

func on_attack_2(event: Event):
	var tower: Tower = self
	var random_spell_id = randi_range(1, 5)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate

	if random_spell_id < 3:
		SFX.sfx_at_unit("FireLordDeathExplode.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 250, 500 + tower.get_level() * 10, tower.calc_spell_crit_no_bonus(), 0)
	elif random_spell_id < 5:
		SFX.sfx_at_unit("AncientProtectorMissile.mdl", c)
		cb_stun.apply_only_timed(tower, c, 0.5 + tower.get_level() * 0.01)
		tower.do_spell_damage(c, 750, tower.calc_spell_crit_no_bonus())
	else:
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 250)

		while true:
			u = it.next()

			if u == null:
				break

			kel_slow.apply_custom_timed(tower, u, 120, 3)

		SFX.sfx_at_unit("FrostNovaTarget.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 250, 250 + tower.get_level() * 8, tower.calc_spell_crit_no_bonus(), 0)

func on_attack_3(event: Event):
	var tower: Tower = self
	var random_spell_id = randi_range(1, 10)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate
	var count: int

	if random_spell_id < 4:
		SFX.sfx_at_unit("FireLordDeathExplode.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 250, 1650 + tower.get_level() * 18, tower.calc_spell_crit_no_bonus(), 0)
	elif random_spell_id < 7:
		SFX.sfx_at_unit("AncientProtectorMissile.mdl", c)
		cb_stun.apply_only_timed(tower, c, 0.5 + tower.get_level() * 0.01)
		tower.do_spell_damage(c, 2000, tower.calc_spell_crit_no_bonus())
	elif random_spell_id < 9:
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 250)

		while true:
			u = it.next()

			if u == null:
				break

			kel_slow.apply_custom_timed(tower, u, 140, 4)

		SFX.sfx_at_unit("FrostNovaTarget.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 250, 800 + tower.get_level() * 10, tower.calc_spell_crit_no_bonus(), 0)
	else:
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 900)

		while true:
			u = it.next()
			count = count + 1

			if count == 6 || u == null:
				break

			SFX.sfx_at_unit("BoltImpact.mdl", u)
			tower.do_spell_damage(u, 1650 + (tower.get_level() * 30), tower.calc_spell_crit_no_bonus())
			# TODO: implement lightning, it's an advanced visual(effect)
			# Lightning.create_from_unit_to_unit("CLPB", tower, u).set_lifetime(0.15)


func on_attack_4(event: Event):
	var tower: Tower = self
	var random_spell_id = randi_range(1, 10)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate
	var count: int

	if random_spell_id < 4:
# 		FireBlast
		if tower.user_int2 == 1:
			tower.user_int = tower.user_int + 1
		else:
			tower.user_int = 1
			tower.user_int2 = 1

		SFX.sfx_at_unit("FireLordDeathExplode.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 300, (3000 + tower.get_level() * 60) * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus(), 0)
	elif random_spell_id < 7:
#		Aftershock
		if tower.user_int2 == 2:
			tower.user_int = tower.user_int + 1
		else:
			tower.user_int = 1
			tower.user_int2 = 2

		SFX.sfx_at_unit("MarkOfChaosTarget.mdl", c)
		cb_stun.apply_only_timed(tower, c, 0.7 + tower.get_level() * 0.02)
		tower.do_spell_damage(c, 6000 * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus())
	elif random_spell_id < 9:
#		FrostNova
		if tower.user_int2 == 3:
			tower.user_int = tower.user_int + 1
		else:
			tower.user_int = 1
			tower.user_int2 = 3

		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 300)

		while true:
			u = it.next()

			if u == null:
				break

			kel_slow.apply_custom_timed(tower, u, 150, 4)

		SFX.sfx_at_unit("FrostNovaTarget.mdl", c)
		SFX.sfx_at_unit("FreezingBreathMissile.mdl", c)
		tower.do_spell_damage_aoe_unit(c, 300, (2000 + tower.get_level() * 80) * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus(), 0)
	else:
#		Lightning Burst
		if tower.user_int2 == 4:
			tower.user_int = tower.user_int + 1
		else:
			tower.user_int = 1
			tower.user_int2 = 4

		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 900)

		while true:
			u = it.next()
			count = count + 1

			if count == 7 || u == null:
				break

			SFX.sfx_at_unit("BoltImpact.mdl", u)
			tower.do_spell_damage(u, (3000 + tower.get_level() * 60) * (1 + ((0.5 + tower.get_level() - 1))), tower.calc_spell_crit_no_bonus())
			# TODO: implement lightning, it's an advanced visual(effect)
			# Lightning.create_from_unit_to_unit("CLPB", tower, u).set_lifetime(0.15)


func on_create(_preceding: Tower):
	var tower: Tower = self
#	Stores how many consecutive times last spell was cast
	tower.user_int = 0
#	Stores which spell was last cast
	tower.user_int2 = 0
