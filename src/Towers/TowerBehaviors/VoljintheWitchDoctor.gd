extends TowerBehavior


# NOTE: time constants have been divided by 25 to account
# for original Game.getGameTime() returning seconds
# multiplied by 25.

# NOTE: changed how wards are stored
# Original script: hashtable with ints and reals
# New script: list of wards


class Ward:
	var position: Vector2 = Vector2.ZERO
	var effect: int = 0
	var duration: float = 0.0
	var is_active: bool = false


var maledict_bt: BuffType
var voljin_pt: ProjectileType
var ward_list: Array[Ward]
var active_ward_count: int = 0
var time_for_next_purify: float
var periodic_is_enabled: bool = true
var first_periodic_event: bool = false
var periodic_interval: float


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var serpent_ward: AbilityInfo = AbilityInfo.new()
	serpent_ward.name = "Serpent Ward"
	serpent_ward.icon = "res://resources/icons/tower_icons/SmallSerpentWard.tres"
	serpent_ward.description_short = "Whenever Vol'jin attacks, he has a chance to summon 1 of 2 [color=GOLD]Serpent Wards[/color] to assist him. Each [color=GOLD]Serpent Ward[/color] attacks a random target in range, dealing attack damage.\n"
	serpent_ward.description_full = "Whenever Vol'jin attacks, he has a 18% chance to summon 1 of 2 [color=GOLD]Serpent Wards[/color] to assist him. Each [color=GOLD]Serpent Ward[/color] lasts 6 seconds modified by this tower's buff duration, deals 20% of Vol'jins attack damage and has Vol'jins current attack speed at cast. Each [color=GOLD]Serpent Ward[/color] attacks a random target in 800 range and has a 35% chance to stack [color=GOLD]Maledict[/color] on attack targets. Wards can not be resummoned and their duration cannot be refreshed.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.2% attack damage\n" \
	+ "+0.1 seconds duration\n" \
	+ "+0.28% chance to summon a ward\n" \
	+ "+1 maximum ward at level 15 and 25\n"
	list.append(serpent_ward)

	var purify: AbilityInfo = AbilityInfo.new()
	purify.name = "Purify"
	purify.icon = "res://resources/icons/holy/white_trinket.tres"
	purify.description_short = "Whenever Vol'jin hits a creep, it purges all buffs and debuffs and deals bonus attack damage based on the purge count. This ability has a 4 second cooldown\n"
	purify.description_full = "Whenever Vol'jin hits a creep, it purges all buffs and debuffs and deals bonus 12% attack damage for each purged effect. This ability has a 4 second cooldown.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "-0.04 seconds cooldown\n" \
	+ "+0.16% damage per purged effect\n"
	list.append(purify)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 0.1)


# NOTE: this tower's tooltip in original game does NOT
# include innate stats
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.0, 0.03)
	modifier.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.08)


func tower_init():
	maledict_bt = BuffType.new("maledict_bt", 0, 0, false, self)
	maledict_bt.set_buff_icon("res://resources/icons/generic_icons/omega.tres")
	maledict_bt.add_event_on_damaged(maledict_bt_on_damaged)
	maledict_bt.add_event_on_expire(maledict_bt_on_expire)
	maledict_bt.add_event_on_purge(maledict_bt_on_purge)
	maledict_bt.set_buff_tooltip("Maledict\nDeals spell damage on expiry.")

	voljin_pt = ProjectileType.create("SerpentWardMissile.mdl", 10, 1200, self)
	voljin_pt.enable_homing(voljin_pt_on_hit, 0)

	
func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Maledict"
	autocast.icon = "res://resources/icons/undead/monster_hand.tres"
	autocast.description_short = "Vol'jin jinxes all units in range with [color=GOLD]Maledict[/color] which deals spell damage to the target.\n"
	autocast.description = "Vol'jin jinxes all units in 800 range with [color=GOLD]Maledict[/color] which will deal spell damage to the target after 8 seconds. The damage is equal to 15% of the total damage received by the target while [color=GOLD]Maledict[/color] was active. [color=GOLD]Maledict[/color] stacks, with each stack adding 3.5% additional damage. If [color=GOLD]Maledict[/color] is purged it deals double damage. This ability is unaffected by Buff Duration.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.14% damage per stack\n"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 800
	autocast.auto_range = 800
	autocast.cooldown = 5
	autocast.mana_cost = 30
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast

	return [autocast]


func on_attack(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var ward_chance: float = 0.18 + 0.0028 * level

	if !tower.calc_chance(ward_chance):
		return

	CombatLog.log_ability(tower, target, "Serpent Ward")

	var max_wards: int
	if level == 25:
		max_wards = 4
	elif level >= 15:
		max_wards = 3
	else:
		max_wards = 2

	var counter: int = 0

	while true:
#		Check whether all wards already exist, if not create one
		var ward: Ward = ward_list[counter]

		if !ward.is_active:
			var x: float = ward.position.x
			var y: float = ward.position.y
			ward.effect = Effect.create_animated("res://src/Effects/WitchDoctorWard.tscn", Vector3(x, y, tower.get_z() - 70), -(45.0 + 90.0 * counter / 4))
			Effect.set_scale(ward.effect, 0.3)
			Effect.set_color(ward.effect, Color8(255, 255, 255, 200))

			ward.is_active = true
			ward.duration = (6.0 + 0.1 * tower.get_level()) * tower.get_prop_buff_duration()

			active_ward_count += 1 # Save the amount of wards
#			The first ward has been created => Start the Periodic Event
			if active_ward_count == 1:
				periodic_is_enabled = true
				periodic_interval = tower.get_current_attack_speed()

#			NOTE: break after successfully creating one wand
#			so that only one wand is created at a time
			break

		counter += 1
		if counter > (max_wards - 1):
			break


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var purged_count: int = 0
	var purify_is_on_cd: bool = time_for_next_purify > Utils.get_time()
	
	if purify_is_on_cd:
		return

	var purify_cd: float = 4.0 - 0.04 * tower.get_level()
	time_for_next_purify = Utils.get_time() + purify_cd

#	Remove buffs (positive and negative buffs) and count them
	while true:
		var purge_friendly: bool = target.purge_buff(true)
		if purge_friendly:
			purged_count += 1

		var purge_unfriendly: bool = target.purge_buff(false)
		if purge_unfriendly:
			purged_count += 1

		var purge_success: bool = purge_friendly || purge_unfriendly

		if !purge_success:
			break

	var damage_multiplier: float = 1.0 + purged_count * (0.12 + 0.0016 * tower.get_level())
	event.damage *= damage_multiplier

	if purged_count != 0:
		var floating_text: String = Utils.format_float(event.damage, 0)
		tower.get_player().display_small_floating_text(floating_text, tower, Color8(255, 150, 255), 0)


func on_create(_preceding: Tower):
	var ward_offsets: Array = [
		Vector2(38, -53),
		Vector2(-43, -45),
		Vector2(-33, 38),
		Vector2(35, 38),
	]

	for offset in ward_offsets:
		var ward_pos: Vector2 = tower.get_position_wc3_2d() + offset
		var ward: Ward = Ward.new()
		ward.position = ward_pos

		ward_list.append(ward)

	active_ward_count = 0
	time_for_next_purify = Utils.get_time() - 4
	periodic_interval = 0.0


func on_destruct():
	for ward in ward_list:
		var effect: int = ward.effect

		if effect != 0:
			Effect.destroy_effect(effect)


# NOTE: original script saves targets in a list. This is
# unsafe. Used Iterate directly instead.
func periodic(event: Event):
	if first_periodic_event:
		periodic_is_enabled = false

		return

	if !periodic_is_enabled:
		return

#	NOTE: original script calls enable_advanced()
#	selectively in some spots. Call it always here to ensure
#	that periodic interval always equals to attack speed.
	event.enable_advanced(tower.get_current_attack_speed(), false)
	
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 800)

	var counter: int = 0

	while true:
		var ward: Ward = ward_list[counter]

		if ward.is_active:
			var random_target: Unit = it.next_random()

			var duration: float = ward.duration - periodic_interval # Set duration to duration - periodic interval

			if duration > 0: # Is there duration remaining?
				if random_target != null: # Is there are unit which can be attacked ?
					# NOTE: here, original script makes the ward
					# model face the creep. This can be skipped
					# because youtd2 no ward model which can
					# rotate.

					# Shoot prohectile
					var x: float = ward.position.x
					var y: float = ward.position.y
					var p: Projectile = Projectile.create_from_point_to_unit(voljin_pt, tower, 1.0, 1.0, Vector3(x, y, 147), random_target, true, false, false)
					p.set_projectile_scale(0.4)

				# Save the remaining duration
				ward.duration = duration
			else: # No more duration
				CombatLog.log_ability(tower, null, "Destroy Serpent Ward")
				ward.is_active = false
				Effect.destroy_effect(ward.effect)
				active_ward_count -= 1

		counter += 1
#		Up to 4 wards with each taking 1 index in the list starting at 0
#		=> 4 wards - 1
		if counter > ward_list.size() - 1:
			break

#	Disable the event
	periodic_is_enabled = false

#	Are there any wards?
	if active_ward_count > 0:
# 		Activate the event
		periodic_is_enabled = true
		periodic_interval = tower.get_current_attack_speed()


func on_autocast(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), tower, 800)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		apply_maledict(tower, next, true)


# NOTE: "voljin_hit()" in original script
func voljin_pt_on_hit(_p: Projectile, target: Unit):
	if target == null:
		return

	var damage: float = tower.get_current_attack_damage_with_bonus() * (0.2 + 0.002 * tower.get_level())

	tower.do_attack_damage(target, damage, tower.calc_attack_multicrit_no_bonus())
	apply_maledict(tower, target, false)


# NOTE: "ApplyMaledict()" in original script
func apply_maledict(caster: Tower, target: Unit, B: bool):
	var buff: Buff = target.get_buff_of_type(maledict_bt)
	var duration: float = 8.0 / caster.get_prop_buff_duration()

	if B && buff == null:
		var new_buff: Buff = maledict_bt.apply_advanced(caster, target, 1, 0, duration)
		new_buff.user_real = 0.0
	elif (buff != null && !B && caster.calc_chance(0.35)) || (buff != null && B == true):
		maledict_bt.apply_advanced(caster, target, buff.get_level() + 1, 0, duration)


# NOTE: "damageEvent()" in original script
func maledict_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	buff.user_real += event.damage


# NOTE: "expireEvent()" in original script
func maledict_bt_on_expire(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var collected_damage: float = buff.user_real
	var stack_count: float = buff.get_level()
	var multiplier_per_stack: float = 0.035 + 0.0014 * tower.get_level()
	var damage_multiplier: float = 0.15 + multiplier_per_stack * stack_count
	var damage: float = collected_damage * damage_multiplier

	tower.do_spell_damage(buffed_unit, damage, tower.calc_spell_crit_no_bonus())


# NOTE: "purgeEvent()" in original script
func maledict_bt_on_purge(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var collected_damage: float = buff.user_real
	var stack_count: float = buff.get_level()
	var multiplier_per_stack: float = 0.07 + 0.0028 * tower.get_level()
	var damage_multiplier: float = 0.3 + multiplier_per_stack * stack_count
	var damage: float = collected_damage * damage_multiplier

	tower.do_spell_damage(buffed_unit, damage, tower.calc_spell_crit_no_bonus())
