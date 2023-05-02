extends Tower


var Poisoned_heart: BuffType


func _get_tier_stats() -> Dictionary:
	return {
		1: {bounce_count = 2, poison_damage = 25, poison_damage_add = 1, poison_duration_add = 0.1},
		2: {bounce_count = 3, poison_damage = 75, poison_damage_add = 3, poison_duration_add = 0.2},
		3: {bounce_count = 4, poison_damage = 150, poison_damage_add = 6, poison_duration_add = 0.3},
		4: {bounce_count = 6, poison_damage = 300, poison_damage_add = 12, poison_duration_add = 0.4},
		5: {bounce_count = 8, poison_damage = 625, poison_damage_add = 25, poison_duration_add = 0.5},
	}


func get_extra_tooltip_text() -> String:
	var poison_damage: String = String.num(_stats.poison_damage, 2)
	var poison_damage_add: String = String.num(_stats.poison_damage_add, 2)
	var poison_duration_add: String = String.num(_stats.poison_duration_add, 2)

	var text: String = ""

	text += "[color=GOLD]Poisoned Heart[/color]\n"
	text += "This tower destroys a piece of the creep's heart on damage. The affected creep takes %s spelldamage every second for 6 seconds.\n" % poison_damage
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s poison damage\n" % poison_damage_add
	text += "+%s seconds poison duration" % poison_duration_add

	return text


func load_specials(_modifier: Modifier):
	_set_attack_style_bounce(_stats.bounce_count, 0.0)


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage, 1.0, 0.0)


func deal_damage(event: Event):
	var b: Buff = event.get_buff()

	var creep: Unit = b.get_buffed_unit()
	var tower: Tower = b.get_caster()
	tower.do_spell_damage(creep, b.user_real, tower.calc_spell_crit_no_bonus())


func tower_init():
	Poisoned_heart = BuffType.new("Poisoned_heart", 9, 0.5, false)
	Poisoned_heart.set_buff_icon("@@0@@")

	Poisoned_heart.add_periodic_event(deal_damage, 1)

	Poisoned_heart.set_buff_tooltip("Poisoned Heart\nThis unit is poisoned and is suffering damage over time.")


func on_damage(event: Event):
	var tower: Tower = self

	var creep: Unit = event.get_target()

	Poisoned_heart.apply_custom_timed(tower, creep, tower.get_level(), 6 + tower.get_level() * _stats.poison_duration_add).user_real = _stats.poison_damage + _stats.poison_damage_add * tower.get_level()
