extends TowerBehavior


# NOTE: implemented falling hammer projectile differently
# because physics based projectiles are not implemented in
# youtd2.

# TODO: look into "Storm Bolt" ability more. It creates a
# line of AoE when projectile hits. The angle of the line is
# equal to projectile's angle. Currently, that means the
# angle of the projectile's movement right before it hit the
# creep. This means that when projectile is turning fast at
# the end the angle can be something unexpected. Check in
# original youtd. Maybe this angle needs to be the angle
# between tower and creep if projectile is interpolated?


var stun_bt: BuffType
var hammer_fall_bt: BuffType
var stormbolt_pt: ProjectileType
var hammer_pt: ProjectileType

const HAMMER_RANGE: float = 1000


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Mystical Storm Hammer[/color]\n"
	text += "Whenever this tower damages a creep, part of the damage is dealt as spell damage and the rest as attack damage. The amount of spell damage depends on the magic resistance of the target. The higher the resistance, the smaller ratio of spell damage dealt. Deals no spell damage against immune creeps and deals no physical damage against banished creeps. If this ability deals all the damage in one type, it will have 5% increased critchance.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1.8% crit chance\n"
	text += " \n"

	text += "[color=GOLD]Storm Bolt[/color]\n"
	text += "When this tower attacks it launches a storm bolt towards the target unit. Upon collision, the bolt deals the towers attack damage to the target and creates a trail of 5 storm explosions. The explosions deal the tower's attack damage to every unit in 85 AOE. Each explosion deals 40% less damage than the previous one.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-1.2% damage reduction\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Mystical Storm Hammer[/color]\n"
	text += "Whenever this tower damages a creep, part of the damage is dealt as spell damage and the rest as attack damage.\n"
	text += " \n"

	text += "[color=GOLD]Storm Bolt[/color]\n"
	text += "When this tower attacks it launches a storm bolt towards the target unit. The storm bolt deals AoE damage.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Summons a hammer which falls from the sky. The hammer deals 10000 spell damage to all units in 600 AoE and stuns them for 1 second. Each of the player's storm tower in 2500 range loses 10% attack damage for 6 seconds but increases the spell damage of the Hammer by 5%. Can gain a maximum of 100% bonus damage.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% damage from towers\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Summons a hammer which falls from the sky and deals AoE damage.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	tower.set_attack_ground_only()
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 0.08)


func tower_init():
	stun_bt = CbStun.new("gryphon_rider_stun", 0, 0, false, self)
	
	hammer_fall_bt = BuffType.new("hammer_fall_bt", 6, 0, false, self)
	var hammer_fall_bt_mod: Modifier = Modifier.new()
	hammer_fall_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -0.1, 0.0)
	hammer_fall_bt.set_buff_modifier(hammer_fall_bt_mod)
	hammer_fall_bt.set_buff_icon("hammer_swing.tres")
	hammer_fall_bt.set_buff_tooltip("Hammer Fall\nReduces attack damage.")

	stormbolt_pt = ProjectileType.create_interpolate("StormBoltMissile.mdl", 1100, self)
	stormbolt_pt.set_event_on_interpolation_finished(stormbolt_pt_on_hit)

	var pt_range: float = HAMMER_RANGE
	var pt_speed: float = 1000
	hammer_pt = ProjectileType.create_ranged("StormBoltMissile.mdl", pt_range, pt_speed, self)
	hammer_pt.set_event_on_expiration(hammer_pt_on_expiration)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Hammer Fall"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 900
	autocast.auto_range = 900
	autocast.cooldown = 10
	autocast.mana_cost = 50
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_attack(event: Event):
	var target: Unit = event.get_target()
	Projectile.create_linear_interpolation_from_unit_to_unit(stormbolt_pt, tower, 1.0, 1.0, tower, target, 0.15, true)


func on_damage(event: Event):
	event.damage = 0


func on_autocast(event: Event):
	var target: Unit = event.get_target()

	var hammer_pos: Vector2 = target.get_position_wc3_2d()
	hammer_pos.y -= HAMMER_RANGE
	var p: Projectile = Projectile.create(hammer_pt, tower, 1.0, tower.calc_spell_crit_no_bonus(), Vector3(hammer_pos.x, hammer_pos.y, 0), 90)

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.PLAYER_TOWERS), 2500.0)
	var damage_multiplier: float = 1.0
	var damage_multiplier_per_tower: float = 0.05 + 0.002 * tower.get_level()

	while true:
		var next: Tower = it.next()

		if next == null:
			break

		if next.get_element() == Element.enm.STORM:
			damage_multiplier += damage_multiplier_per_tower
			hammer_fall_bt.apply(tower, next, 0)

		if damage_multiplier >= 2.0:
			break

	p.user_real *= damage_multiplier


func stormbolt_pt_on_hit(p: Projectile, target: Unit):
	if target != null:
		var stormbolt_damage: float = tower.get_current_attack_damage_with_bonus()
		deal_damage(target, stormbolt_damage)

	line_damage(Vector2(p.get_x(), p.get_y()), p.get_direction())


func hammer_pt_on_expiration(p: Projectile):
	var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(p.get_x(), p.get_y()), 600.0)
	var hammer_damage: float = p.user_real

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		deal_damage(next, hammer_damage)
		stun_bt.apply_only_timed(tower, next, 1.0)


func deal_damage(target: Unit, damage: float):
	var spell: float = target.get_prop_spell_damage_received()
	var phys: float = target.get_prop_atk_damage_received()
	var r: float = 0.0
	var crit: float = 0.0

#	calc spell damage taken
#	Immune?
	if target.is_immune():
#		0% spell damage
		spell = 0

#	calc physical damage taken
#	Banished?
	if target.is_banished():
#		0% physical damage
		phys = 0
	else:
#		armor
		phys *= target.get_current_armor_damage_reduction()

#	we don't want anything below zero!
	if spell < 0.0:
		spell = 0

	if phys < 0.0:
		phys = 0

#	Result are how much physical and spell damage the unit takes.
#	Probably adding these two wont result in 100% so we have to scale them
	r = spell + phys
	if r <= 0:
#		shit happened...
		return

	if r != 1.0:
		spell /= r
		phys /= r

#	crit bonus?
	if phys == 1.0 || spell == 1.0:
		crit = 0.08 + 0.018 * tower.get_level()

# 	Now we know what we need to know to deal damage
	tower.do_spell_damage(target, damage * spell, tower.calc_spell_crit(crit, 0.0))
	tower.do_attack_damage(target, damage * phys, tower.calc_attack_multicrit(crit, 0, 0))


func line_damage(origin_pos: Vector2, direction: float):
	var distance: float = 128.0
	var damage: float = tower.get_current_attack_damage_with_bonus()
	var i: int = 0
	var dmg_multiplier: float = 0.6 + 0.012 * tower.get_level()

	while true:
		if i >= 5 || !Utils.unit_is_valid(tower):
			break

		var current_distance: float = distance * i
		var offset: Vector2 = Vector2.from_angle(deg_to_rad(direction)) * current_distance
		var current_pos: Vector2 = origin_pos + offset

		var it: Iterate = Iterate.over_units_in_range_of(tower, TargetType.new(TargetType.CREEPS), Vector2(current_pos.x, current_pos.y), 85)

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			deal_damage(next, damage)

		var clap_effect: int = Effect.create_scaled("ThunderClapCaster", Vector3(current_pos.x, current_pos.y, 0.0), 0.0, 5)
		Effect.set_lifetime(clap_effect, 1.5)
		var bolt_effect: int = Effect.create_colored("MonsoonBoltTarget", Vector3(current_pos.x, current_pos.y, 0.0), 0.0, 5, Color8(0, 0, 0, 255))
		Effect.set_lifetime(bolt_effect, 2.5)

		damage *= dmg_multiplier
		i += 1
		await Utils.create_timer(0.15, self).timeout
