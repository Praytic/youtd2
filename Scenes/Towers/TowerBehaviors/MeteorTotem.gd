extends TowerBehavior


# NOTE: the autocast target_self in original script is set
# to true BUT the autocast callback does a check "if target
# != tower:", so the final behavior is Meteor Totem does NOT
# apply the Attraction buff to itself.
# 
# I set autocast target_self to false to make it less
# confusing.


var attraction_bt: BuffType
var torture_bt: BuffType
var missile_pt: ProjectileType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Torture[/color]\n"
	text += "Targets damaged by this tower are debuffed for 2.5 seconds. Whenever a debuffed creep is dealt at least 500 attackdamage it receives an additional 8% of that damage as spell damage. This ability cannot crit.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.05 seconds duration\n"
	text += "+0.1% damage as spell damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Torture[/color]\n"
	text += "Targets damaged by this tower are debuffed. Whenever a debuffed creep takes a long of damage it will take even more extra damage.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "This tower buffs 4 towers in 500 range and gives them a 35% attackspeed adjusted chance on attack to release a meteor dealing 200 spell damage, or a 100% chance to release a meteor on spell cast dealing 500 spell damage. The Meteors fly towards a random target in 1000 range and deal damage in 220 AoE around the main target. The buff lasts until a meteor is released.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1 tower buffed every 5 levels\n"
	text += "+8 spell damage on attack\n"
	text += "+20 spell damage on cast\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "This tower buffs 4 towers in range and gives them a chance to release a meteor when attacking or casting spells.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	tower.set_attack_style_splash({325: 0.5})


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Attraction", 500, TargetType.new(TargetType.TOWERS))]


func tower_init():
	attraction_bt = BuffType.new("attraction_bt", 2.5, 0.05, true, self)
	attraction_bt.add_event_on_attack(attraction_bt_on_attack)
	attraction_bt.add_event_on_spell_casted(attraction_bt_on_spell_casted)
	attraction_bt.set_buff_icon("res://Resources/Textures/GenericIcons/burning_meteor.tres")
	attraction_bt.set_buff_tooltip("Attraction\nReleases a meteor on a random creep.")

	torture_bt = BuffType.new("torture_bt", 2.5, 0.05, false, self)
	torture_bt.set_buff_icon("res://Resources/Textures/GenericIcons/animal_skull.tres")
	torture_bt.add_event_on_damaged(torture_bt_on_damaged)
	torture_bt.set_buff_tooltip("Torture\nSometimes deals damage.")

	missile_pt = ProjectileType.create_interpolate("LordofFlameMissile.mdl", 950, self)
	missile_pt.set_event_on_interpolation_finished(missile_pt_on_hit)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Attraction"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Textures/ItemIcons/1_unused_fire_bowl_2.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 500
	autocast.auto_range = 500
	autocast.cooldown = 4
	autocast.mana_cost = 0
	autocast.target_self = false
	autocast.is_extended = true
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	torture_bt.apply(tower, target, tower.get_level())


func on_autocast(_event: Event):
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)
	var number: int = 4 + int(tower.get_level() / 5)

	while true:
		var target: Unit = it.next_random()

		if target == null || number == 0:
			break

		if target != tower:
			var buff: Buff = attraction_bt.apply(tower, target, tower.get_level())
			buff.user_int = 0


func missile_pt_on_hit(projectile: Projectile, _target: Unit):
	tower.do_spell_damage_aoe(Vector2(projectile.get_x(), projectile.get_y()), 220, projectile.user_int, tower.calc_spell_crit_no_bonus(), 0)
	SFX.sfx_at_pos("DoomDeath.mdl", projectile.get_position_canvas())


func attraction_bt_on_attack(event: Event):
	var buff: Buff = event.get_buff()
	var buffed: Tower = buff.get_buffed_unit()

	if buffed.calc_chance(buffed.get_base_attackspeed() * 0.35):
		var triggered_by_attack: bool = true
		release_meteor(buff, triggered_by_attack)


func attraction_bt_on_spell_casted(event: Event):
	var buff: Buff = event.get_buff()
	var triggered_by_attack: bool = false
	release_meteor(buff, triggered_by_attack)


func release_meteor(buff: Buff, triggered_by_attack: bool):
	var buffed: Tower = buff.get_buffed_unit()
	var it: Iterate = Iterate.over_units_in_range_of_caster(buffed, TargetType.new(TargetType.CREEPS), 1000)
	var result: Unit = it.next_random()
	var level: int = tower.get_level()

	if result != null:
		var projectile: Projectile = Projectile.create_bezier_interpolation_from_unit_to_unit(missile_pt, buffed, 1.0, 1.0, buffed, result, 0.0, 0, 0.0, true)
		
		var projectile_damage: int
		if triggered_by_attack:
			projectile_damage = 200 + 8 * level
		else:
			projectile_damage = 500 + 20 * level

		projectile.user_int = projectile_damage

	buff.remove_buff()


func torture_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var caster: Tower = buff.get_caster()
	var damage: float = event.damage * (0.08 + 0.001 * caster.get_level())
	var target: Creep = buff.get_buffed_unit()

	if event.damage >= 500 && !event.is_spell_damage():
		caster.do_spell_damage(target, damage, 1.0)
		var floating_text: String = Utils.format_float(damage * caster.get_prop_spell_damage_dealt(), 0)
		caster.get_player().display_small_floating_text(floating_text, target, Color8(255, 150, 150), 20)
