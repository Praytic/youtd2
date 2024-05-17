extends TowerBehavior


# NOTE: original script did thunder by enabling periodic
# event. Changed to use a bool flag instead.


var stun_bt: BuffType


var bolt_count: int = 0
var thunder_effect: int = 0
var thunder_is_enabled: bool = false


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var electrified_attack: AbilityInfo = AbilityInfo.new()
	electrified_attack.name = "Electrified Attack"
	electrified_attack.icon = "res://resources/icons/trinkets/claw_03.tres"
	electrified_attack.description_short = "Whenever Zeus hits the main target, he deals additional AoE spell damage.\n"
	electrified_attack.description_full = "Whenever Zeus hits the main target, he deals an additional 500 spell damage in 175 AoE around their target.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+20 spell damage\n"
	list.append(electrified_attack)

	var divine_hammer: AbilityInfo = AbilityInfo.new()
	divine_hammer.name = "Divine Hammer"
	divine_hammer.icon = "res://resources/icons/blunt_weapons/hammer_02.tres"
	divine_hammer.description_short = "Whenever Zeus kills a creep he restores mana.\n"
	divine_hammer.description_full = "Whenever Zeus kills a creep he restores 5% of his maximum mana.\n"
	list.append(divine_hammer)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)
	triggers.add_periodic_event(periodic, 0.2)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 5.0)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()
	
	autocast.title = "Thunderstorm"
	autocast.icon = "res://resources/icons/tower_icons/ruined_monolith.tres"
	autocast.description_short = "Zeus releases a mighty thunderstorm, this thunder storm strikes creeps in range and stuns them.\n"
	autocast.description = "Zeus releases a mighty thunderstorm, this thunder storm strikes creeps in 1000 range for 2500 spell damage and stuns them for 0.5 seconds (20% chance on bosses). There is a maximum of 20 lightning strikes.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+125 damage\n" \
	+ "+1 lightning strike per 5 levels\n"
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

	return [autocast]


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var damage: float = 500 + 20 * tower.get_level()

	if event.is_main_target():
		tower.do_spell_damage_aoe_unit(target, 175, damage, tower.calc_spell_crit_no_bonus(), 0.0)


func on_kill(_event: Event):
	tower.add_mana_perc(0.05)


func on_destruct():
	if thunder_effect != 0:
		Effect.destroy_effect(thunder_effect)
		thunder_effect = 0


func periodic(_event: Event):
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
				stun_bt.apply_only_timed(tower, bolt_target, 0.5)

			SFX.sfx_on_unit("MonsoonBoltTarget.mdl", bolt_target, Unit.BodyPart.ORIGIN)

		bolt_count -= 1
	else:
		if thunder_effect != 0:
			Effect.destroy_effect(thunder_effect)
			thunder_effect = 0


func on_autocast(_event: Event):
	bolt_count = 20 + int(0.2 * tower.get_level())

	if thunder_effect == 0:
		thunder_effect = Effect.create_animated("PurgeBuffTarget.mdl", Vector3(tower.get_x() - 16, tower.get_y() - 16, tower.get_z()), 0)

	thunder_is_enabled = true

