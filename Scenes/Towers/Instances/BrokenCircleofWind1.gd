extends Tower


var sternbogen_broken_wind: BuffType

func get_tier_stats() -> Dictionary:
	return {
		1: {catch_chance = 0.20, catch_chance_add = 0.003, cyclone_duration = 0.5, cyclone_damage = 20, cyclone_damage_add = 2},
		2: {catch_chance = 0.22, catch_chance_add = 0.004, cyclone_duration = 0.6, cyclone_damage = 68, cyclone_damage_add = 7},
		3: {catch_chance = 0.24, catch_chance_add = 0.005, cyclone_duration = 0.7, cyclone_damage = 196, cyclone_damage_add = 20},
		4: {catch_chance = 0.26, catch_chance_add = 0.006, cyclone_duration = 0.8, cyclone_damage = 600, cyclone_damage_add = 60},
		5: {catch_chance = 0.28, catch_chance_add = 0.007, cyclone_duration = 1.0, cyclone_damage = 1120, cyclone_damage_add = 112},
	}


func get_extra_tooltip_text() -> String:
	var catch_chance: String = String.num(_stats.catch_chance * 100, 2)
	var cyclone_duration: String = String.num(_stats.cyclone_duration, 2)
	var cyclone_damage: String = String.num(_stats.cyclone_damage, 2)
	var cyclone_damage_add: String = String.num(_stats.cyclone_damage_add, 2)
	var catch_chance_add: String = String.num(_stats.catch_chance_add * 100, 2)

	var text: String = ""

	text += "[color=GOLD]Wind of Death[/color]\n"
	text += "On attack this tower has a %s%% chance to catch a ground, non-boss unit in a cyclone for %s seconds, dealing %s physical damage to all units in 300 AoE when it falls back down. Falling champions deal 25 more damage.\n" % [catch_chance, cyclone_duration, cyclone_damage]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage\n" % cyclone_damage_add
	text += "+%s%% chance to catch" % catch_chance_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_AIR, 0.70, 0.02)


func tower_init():
	sternbogen_broken_wind = CbStun.new("sternbogen_broken_wind", 1.0, 0, false, self)
	sternbogen_broken_wind.set_buff_icon("@@0@@")
	sternbogen_broken_wind.add_event_on_create(cyclone_creep_up)
	sternbogen_broken_wind.add_periodic_event(cyclone_creep_turn, 0.1)
	sternbogen_broken_wind.set_event_on_cleanup(cyclone_creep_down)


func on_attack(event: Event):
	var tower: Unit = self

	var target: Unit = event.get_target()
	var damage: float = _stats.cyclone_damage + _stats.cyclone_damage_add * tower.get_level()
	var b: Buff

	if (target.get_size() == CreepSize.enm.MASS || target.get_size() == CreepSize.enm.NORMAL || target.get_size() == CreepSize.enm.CHAMPION):
		if (tower.calc_chance(_stats.catch_chance + (_stats.catch_chance_add * tower.get_level()))):
			b = target.get_buff_of_type(sternbogen_broken_wind)
			
			if b != null:
				damage = max(b.user_real3, damage)

			b = sternbogen_broken_wind.apply_custom_timed(tower, target, tower.get_level(), _stats.cyclone_duration)

			if b != null:
				b.user_real3 = damage


func cyclone_creep_up(event: Event):
	var b: Buff = event.get_buff()

	var c: Unit = b.get_buffed_unit()
#	(start) cyclone animation
	b.user_int = Effect.create_animated("res://Scenes/Effects/CycloneTarget.tscn", c.get_x(), c.get_y(), 0.0, 0.0)
	Effect.no_death_animation(b.user_int)
#   move creep up
	c.adjust_height(300, 1000)


func cyclone_creep_turn(event: Event):
	var b: Buff = event.get_buff()

	var real_unit: Unit = b.get_buffed_unit()
	real_unit.set_unit_facing(real_unit.get_unit_facing() + 150.0)
	real_unit = null


func cyclone_creep_down(event: Event):
	var b: Buff = event.get_buff()

	var t: Unit = b.get_caster()
	var c: Unit = b.get_buffed_unit()
	var ratio: float = 1

#	set units back (down)
	c.adjust_height(-300, 2500)
#	remove the cyclone
	Effect.destroy_effect(b.user_int)
# 	effects
	var thunder_clap_effect: int = Effect.create_simple_at_unit("res://Scenes/Effects/ThunderClapCaster.tscn", c)
	Effect.destroy_effect(thunder_clap_effect)
	var bolt_impact: int = Effect.create_simple_at_unit("res://Scenes/Effects/BoltImpact.tscn", c)
	Effect.destroy_effect(bolt_impact)
#   do damage
	if c.get_size() == CreepSize.enm.CHAMPION:
		ratio = 1.25

	t.do_attack_damage_aoe_unit(c, ratio * 300.0, b.user_real3, t.calc_attack_multicrit(0, 0, 0), 0.0)
