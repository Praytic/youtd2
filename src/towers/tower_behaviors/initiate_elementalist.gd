extends TowerBehavior

# NOTE: too many differences between tiers. Had to make
# separate code paths for each tier.

# NOTE: original script has typos. Fixed them.
# 
# 1. 50 dmg for Frost Nova of 2nd tier. Fixed it to 250.
# 
# 2. Used aoe damage for "Aftershork" tier 3. Fixed to
#    single target damage.


var stun_bt: BuffType
var slow_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var elemental_fury: AbilityInfo = AbilityInfo.new()
	elemental_fury.name = "Elemental Fury"
	elemental_fury.icon = "res://resources/icons/hud/research_elements.tres"
	elemental_fury.description_short = "Consecutive casts of the same spell will deal more damage.\n"
	elemental_fury.description_full = "Consecutive casts of the same spell will deal 50% more damage.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage\n"

	var elemental_chaos_1: AbilityInfo = AbilityInfo.new()
	elemental_chaos_1.name = "Elemental Chaos"
	elemental_chaos_1.icon = "res://resources/icons/tower_icons/ball_lightning_accelerator.tres"
	elemental_chaos_1.description_short = "Elementalist casts a random spell on attack.\n"
	elemental_chaos_1.description_full = "Elementalist casts one of the following spells on attack:\n" \
	+ " \n" \
	+ "[color=ORANGE]Fire Blast:[/color] 66% chance, 200 AoE, 190 spell damage\n" \
	+ "[color=ORANGE]Frost Nova:[/color] 33% chance, 250 AoE, 125 spell damage, 10% slow for 3 seconds\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+7.6 spell damage [color=ORANGE](Fire Blast)[/color]\n" \
	+ "+5 spell damage [color=ORANGE](Frost Nova)[/color]\n"

	var elemental_chaos_2: AbilityInfo = AbilityInfo.new()
	elemental_chaos_2.name = "Elemental Chaos"
	elemental_chaos_2.icon = "res://resources/icons/tower_icons/ball_lightning_accelerator.tres"
	elemental_chaos_2.description_short = "Elementalist casts a random spell on attack.\n"
	elemental_chaos_2.description_full = "Elementalist casts one of the following spells on attack:\n" \
	+ " \n" \
	+ "[color=ORANGE]Fire Blast:[/color] 40% chance, 250 AoE, 500 spell damage\n" \
	+ "[color=ORANGE]Frost Nova:[/color] 20% chance, 250 AoE, 250 spell damage, 12% slow for 3 seconds\n" \
	+ "[color=ORANGE]Aftershock:[/color] 40% chance, 750 spell damage, 0.5 seconds stun\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+10 spell damage [color=ORANGE](Fire Blast)[/color]\n" \
	+ "+8 spell damage [color=ORANGE](Frost Nova)[/color]\n" \
	+ "+0.01 seconds stun [color=ORANGE](Aftershock)[/color]\n"

	var elemental_chaos_3: AbilityInfo = AbilityInfo.new()
	elemental_chaos_3.name = "Elemental Chaos"
	elemental_chaos_3.icon = "res://resources/icons/tower_icons/ball_lightning_accelerator.tres"
	elemental_chaos_3.description_short = "Elementalist casts a random spell on attack.\n"
	elemental_chaos_3.description_full = "Elementalist casts one of the following spells on attack:\n" \
	+ " \n" \
	+ "[color=ORANGE]Fire Blast:[/color] 30% chance, 250 AoE, 1650 spell damage\n" \
	+ "[color=ORANGE]Frost Nova:[/color] 20% chance, 250 AoE, 800 spell damage, 14% slow for 4 seconds\n" \
	+ "[color=ORANGE]Aftershock:[/color] 30% chance, 2000 spell damage, 0.5 seconds stun\n" \
	+ "[color=ORANGE]Lightning Burst:[/color] 20% chance, 1650 spell damage, affects 5 random targets in 900 range\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+18 spell damage [color=ORANGE](Fire Blast)[/color]\n" \
	+ "+10 spell damage [color=ORANGE](Frost Nova)[/color]\n" \
	+ "+0.01 seconds stun [color=ORANGE](Aftershock)[/color]\n" \
	+ "+30 damage [color=ORANGE](Lightning Burst)[/color]\n"

	var elemental_chaos_4: AbilityInfo = AbilityInfo.new()
	elemental_chaos_4.name = "Elemental Chaos"
	elemental_chaos_4.icon = "res://resources/icons/tower_icons/ball_lightning_accelerator.tres"
	elemental_chaos_4.description_short = "Elementalist casts a random spell on attack.\n"
	elemental_chaos_4.description_full = "Elementalist casts one of the following spells on attack:\n" \
	+ " \n" \
	+ "[color=ORANGE]Fire Blast:[/color] 30% chance, 300 AoE, 3000 spell damage\n" \
	+ "[color=ORANGE]Frost Nova:[/color] 20% chance, 300 AoE, 2000 spell damage, 15% slow for 4 seconds\n" \
	+ "[color=ORANGE]Aftershock:[/color] 30% chance, 6000 spell damage, 0.7 seconds stun\n" \
	+ "[color=ORANGE]Lightning Burst:[/color] 20% chance, 3000 spell damage, affects 6 random targets in 900 range\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+60 spell damage [color=ORANGE](Fire Blast)[/color]\n" \
	+ "+80 spell damage [color=ORANGE](Frost Nova)[/color]\n" \
	+ "+0.02 seconds stun [color=ORANGE](Aftershock)[/color]\n" \
	+ "+60 spell damage [color=ORANGE](Lightning Burst)[/color]\n"

	match tower.get_tier():
		1: list.append(elemental_chaos_1)
		2: list.append(elemental_chaos_2)
		3: list.append(elemental_chaos_3)
		4:
			list.append(elemental_fury)
			list.append(elemental_chaos_4)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)

	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_modifier(slow_bt_mod)
	slow_bt.set_buff_tooltip("Slow\nReduces movement speed.")


func on_attack(event: Event):
	match tower.get_tier():
		1: return on_attack_1(event)
		2: return on_attack_2(event)
		3: return on_attack_3(event)
		4: return on_attack_4(event)

	return ""


func on_attack_1(event: Event):
	var random_spell_id = Globals.synced_rng.randi_range(1, 3)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate

	if random_spell_id < 3:
		CombatLog.log_ability(tower, c, "Fire Blast")

		Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 200, 190 + tower.get_level() * 7.6, tower.calc_spell_crit_no_bonus(), 0)
	else:
		CombatLog.log_ability(tower, c, "Frost Nova")
		
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 250)

		while true:
			u = it.next()

			if u == null:
				break

			slow_bt.apply_custom_timed(tower, u, 100, 3)

		Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 250, 125 + tower.get_level() * 5, tower.calc_spell_crit_no_bonus(), 0)
			

func on_attack_2(event: Event):
	var random_spell_id = Globals.synced_rng.randi_range(1, 5)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate

	if random_spell_id < 3:
		CombatLog.log_ability(tower, c, "Fire Blast")
		
		Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 250, 500 + tower.get_level() * 10, tower.calc_spell_crit_no_bonus(), 0)
	elif random_spell_id < 5:
		CombatLog.log_ability(tower, c, "Aftershock")
		
		Effect.create_simple_at_unit("res://src/effects/ancient_protector_missile.tscn", c)
		stun_bt.apply_only_timed(tower, c, 0.5 + tower.get_level() * 0.01)
		tower.do_spell_damage(c, 750, tower.calc_spell_crit_no_bonus())
	else:
		CombatLog.log_ability(tower, c, "Frost Nova")
		
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 250)

		while true:
			u = it.next()

			if u == null:
				break

			slow_bt.apply_custom_timed(tower, u, 120, 3)

		Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 250, 250 + tower.get_level() * 8, tower.calc_spell_crit_no_bonus(), 0)

func on_attack_3(event: Event):
	var random_spell_id = Globals.synced_rng.randi_range(1, 10)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate
	var count: int

	if random_spell_id < 4:
		CombatLog.log_ability(tower, c, "Fire Blast")
		
		Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 250, 1650 + tower.get_level() * 18, tower.calc_spell_crit_no_bonus(), 0)
	elif random_spell_id < 7:
		CombatLog.log_ability(tower, c, "Aftershock")
		
		Effect.create_simple_at_unit("res://src/effects/ancient_protector_missile.tscn", c)
		stun_bt.apply_only_timed(tower, c, 0.5 + tower.get_level() * 0.01)
		tower.do_spell_damage(c, 2000, tower.calc_spell_crit_no_bonus())
	elif random_spell_id < 9:
		CombatLog.log_ability(tower, c, "Frost Nova")
		
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 250)

		while true:
			u = it.next()

			if u == null:
				break

			slow_bt.apply_custom_timed(tower, u, 140, 4)

		Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 250, 800 + tower.get_level() * 10, tower.calc_spell_crit_no_bonus(), 0)
	else:
		CombatLog.log_ability(tower, c, "Lightning Burst")
		
		it = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), c, 900)

		while true:
			u = it.next()
			count = count + 1

			if count == 6 || u == null:
				break

			Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", u)
			tower.do_spell_damage(u, 1650 + (tower.get_level() * 30), tower.calc_spell_crit_no_bonus())
			var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, u)
			lightning.modulate = Color.LIGHT_BLUE
			lightning.set_lifetime(0.15)


func on_attack_4(event: Event):
	var random_spell_id = Globals.synced_rng.randi_range(1, 10)
	var c: Creep = event.get_target()
	var u: Unit
	var it: Iterate
	var count: int

	if random_spell_id < 4:
# 		FireBlast
		CombatLog.log_ability(tower, c, "Fire Blast")
		
		if tower.user_int2 == 1:
			tower.user_int = tower.user_int + 1
		else:
			tower.user_int = 1
			tower.user_int2 = 1

		Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 300, (3000 + tower.get_level() * 60) * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus(), 0)
	elif random_spell_id < 7:
#		Aftershock
		CombatLog.log_ability(tower, c, "Aftershock")
		
		if tower.user_int2 == 2:
			tower.user_int = tower.user_int + 1
		else:
			tower.user_int = 1
			tower.user_int2 = 2

		Effect.create_simple_at_unit("res://src/effects/ancient_protector_missile.tscn", c)
		stun_bt.apply_only_timed(tower, c, 0.7 + tower.get_level() * 0.02)
		tower.do_spell_damage(c, 6000 * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus())
	elif random_spell_id < 9:
#		FrostNova
		CombatLog.log_ability(tower, c, "Frost Nova")
		
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

			slow_bt.apply_custom_timed(tower, u, 150, 4)

		Effect.create_simple_at_unit("res://src/effects/frost_bolt_missile.tscn", c)
		Effect.create_simple_at_unit("res://src/effects/freezing_breath.tscn", c)
		tower.do_spell_damage_aoe_unit(c, 300, (2000 + tower.get_level() * 80) * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus(), 0)
	else:
#		Lightning Burst
		CombatLog.log_ability(tower, c, "Lightning Burst")
		
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

			Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", u)
			tower.do_spell_damage(u, (3000 + tower.get_level() * 60) * (1 + ((0.5 + tower.get_level() * 0.01) * (tower.user_int - 1))), tower.calc_spell_crit_no_bonus())
			var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, tower, u)
			lightning.modulate = Color.LIGHT_BLUE
			lightning.set_lifetime(0.15)


func on_create(_preceding: Tower):
#	Stores how many consecutive times last spell was cast
	tower.user_int = 0
#	Stores which spell was last cast
	tower.user_int2 = 0
