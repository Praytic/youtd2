extends Tower


# NOTE: original script did thunder by enabling periodic
# event. Changed to use a bool flag instead.


var cb_stun: BuffType


var bolt_count: int = 0
var thunder_effect: int = 0
var thunder_is_enabled: bool = false


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Electrified Attack[/color]\n"
	text += "Zeus's attacks deal an additional 500 spelldamage in 175 AoE around their target. \n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+20 spelldamage\n"
	text += " \n"

	text += "[color=GOLD]Divine Hammer[/color]\n"
	text += "Whenever Zeus kills a creep he restores 5% of his maximum mana.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Electrified Attack[/color]\n"
	text += "Zeus's attacks deal an additional AoE spell damage. \n"
	text += " \n"

	text += "[color=GOLD]Divine Hammer[/color]\n"
	text += "Whenever Zeus kills a creep he restores some of his mana.\n"

	return text



func get_autocast_description() -> String:
	var text: String = ""

	text += "Zeus releases a mighty thunderstorm, this thunder storm strikes creeps in 1000 range for 2500 spelldamage and stuns them for 0.5 seconds (20% chance on bosses). There is a maximum of 20 lightning strikes.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+125 damage\n"
	text += "+1 lightning strike per 5 levels\n"

	return text


func get_autocast_description_short() -> String:
	return "Zeus releases a mighty thunderstorm, this thunder storm strikes creeps in range and stuns them.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)
	triggers.add_periodic_event(periodic, 0.2)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 5.0)


func tower_init():
	cb_stun = CbStun.new("zeus_stun", 0, 0, false, self)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Thunderstorm"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 1000
	autocast.auto_range = 1000
	autocast.cooldown = 10
	autocast.mana_cost = 90
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var damage: float = 500 + 20 * tower.get_level()

	if event.is_main_target():
		tower.do_spell_damage_aoe_unit(target, 175, damage, tower.calc_spell_crit_no_bonus(), 0.0)


func on_kill(_event: Event):
	var tower: Tower = self
	tower.add_mana_perc(0.05)


func on_destruct():
	if thunder_effect != 0:
		Effect.destroy_effect(thunder_effect)
		thunder_effect = 0


func periodic(_event: Event):
	var tower: Tower = self
	var bolt_damage: float = 2500 + 125 * tower.get_level()

	if !thunder_is_enabled:
		return

	if bolt_count > 0:
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1200)
		var bolt_target: Creep = it.next_random()

		if bolt_target != null:
			tower.do_spell_damage(bolt_target, bolt_damage, tower.calc_spell_crit_no_bonus())

			var do_stun: bool
			if bolt_target.get_size() >= CreepSize.enm.BOSS:
				do_stun = tower.calc_chance(0.20)
			else:
				do_stun = true

			if do_stun:
				cb_stun.apply_only_timed(tower, bolt_target, 0.5)

			SFX.sfx_on_unit("MonsoonBoltTarget.mdl", bolt_target, "origin")

		bolt_count -= 1
	else:
		if thunder_effect != 0:
			Effect.destroy_effect(thunder_effect)
			thunder_effect = 0


func on_autocast(_event: Event):
	var tower: Tower = self

	bolt_count = 20 + int(0.2 * tower.get_level())

	if thunder_effect == 0:
		thunder_effect = Effect.create_animated("PurgeBuffTarget.mdl", tower.get_visual_x() - 16, tower.get_visual_y() - 16, 50, 0)

	thunder_is_enabled = true

