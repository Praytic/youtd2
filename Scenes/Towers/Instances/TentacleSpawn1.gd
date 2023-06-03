extends Tower


var drol_tentacleDot: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {apply_level = 1, periodic_damage = 20, periodic_damage_add = 0.8},
		2: {apply_level = 2, periodic_damage = 60, periodic_damage_add = 2.4},
		3: {apply_level = 3, periodic_damage = 120, periodic_damage_add = 4.8},
		4: {apply_level = 4, periodic_damage = 240, periodic_damage_add = 10},
		5: {apply_level = 5, periodic_damage = 480, periodic_damage_add = 20},
		6: {apply_level = 6, periodic_damage = 960, periodic_damage_add = 40},
	}


func get_extra_tooltip_text() -> String:
	var increased_spell_damage: String = String.num((0.02 + 0.01 * _stats.apply_level) * 100, 2)
	var periodic_damage: String = String.num(_stats.periodic_damage, 2)
	var periodic_damage_add: String = String.num(_stats.periodic_damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Rend[/color]\n"
	text += "The tentacle has a 25%% chance to rend a target, making it suffer %s%% increased spell damage and dealing %s spell damage per second for 6 seconds. Does not stack.\n" % [increased_spell_damage, periodic_damage]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1%% chance\n"
	text += "+%s spell damage per second" % periodic_damage_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.02, 0.01)

	drol_tentacleDot = BuffType.new("drol_tentacleDot", 6, 0, false, self)
	drol_tentacleDot.set_buff_icon("@@0@@")
	drol_tentacleDot.add_periodic_event(drol_tentacleDamage, 1)
	drol_tentacleDot.set_buff_modifier(m)
	drol_tentacleDot.set_buff_tooltip("Rend\nThis unit has been rended, it receives periodic damage and also takes increased spell damage.")


func drol_tentacleDamage(event: Event):
	var b: Buff = event.get_buff()

	if !b.get_buffed_unit().is_immune():
		b.get_caster().do_spell_damage(b.get_buffed_unit(), b.user_real, b.get_caster().calc_spell_crit_no_bonus())
		SFX.sfx_on_unit("Objects/Spawnmodels/Human/HumanBlood/HumanBloodRifleman.mdl", b.get_buffed_unit(), "chest")


func on_damage(event: Event):
	var tower = self

	if !tower.calc_chance(0.25 + tower.get_level() * 0.01):
		return

	drol_tentacleDot.apply(tower, event.get_target(), _stats.apply_level).user_real = _stats.periodic_damage + _stats.periodic_damage_add * tower.get_level()
