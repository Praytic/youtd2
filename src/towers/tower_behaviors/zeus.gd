extends TowerBehavior


# NOTE: original script did thunder by enabling periodic
# event. Changed to use a bool flag instead.


var stun_bt: BuffType


var bolt_count: int = 0
var thunder_effect: int = 0
var thunder_is_enabled: bool = false


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)
	triggers.add_periodic_event(periodic, 0.2)


func tower_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)


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

			Effect.create_simple_at_unit("res://src/effects/monsoon_bolt.tscn", bolt_target)

		bolt_count -= 1
	else:
		if thunder_effect != 0:
			Effect.destroy_effect(thunder_effect)
			thunder_effect = 0


func on_autocast(_event: Event):
	bolt_count = 20 + int(0.2 * tower.get_level())

	if thunder_effect == 0:
		thunder_effect = Effect.create_simple_at_unit("res://src/effects/purge_buff_target.tscn", tower)
		Effect.set_auto_destroy_enabled(thunder_effect, false)

	thunder_is_enabled = true

