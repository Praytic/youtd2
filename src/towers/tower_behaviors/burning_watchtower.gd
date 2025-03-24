extends TowerBehavior


var burning_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bonus_damage = 1.0, bonus_damage_add = 0.10, explode_damage = 49},
		2: {bonus_damage = 2.5, bonus_damage_add = 0.25, explode_damage = 277},
		3: {bonus_damage = 4.0, bonus_damage_add = 0.40, explode_damage = 750},
		4: {bonus_damage = 5.5, bonus_damage_add = 0.55, explode_damage = 1875},
	}


# b.userReal: The user Real is the current bonus damage of the buff. Init with 0
# NOTE: initOnCreate() in original script
func burning_bt_on_create(event: Event):
	var b: Buff = event.get_buff()
	b.user_real = 0.0
	b.user_int = 0


# Increase damage gain and do direct damage to the target by setting the event damage
# NOTE: damageOnFireAttack() in original script
func burning_bt_on_damaged(event: Event):
	var b: Buff = event.get_buff()

	var damage_gain: float
	var damage_factor: float
	var caster: Tower = b.get_caster()
	var attacker: Tower = event.get_target()
	var is_burning_tower: bool

	if attacker.get_element() == Element.enm.FIRE:
		is_burning_tower = attacker.get_family() == caster.get_family()

		if is_burning_tower:
			damage_factor = 1.0
		else:
			damage_factor = 0.3

		damage_gain = damage_factor * b.get_level() * 0.01
		b.user_real = b.user_real + damage_gain
		event.damage = event.damage + b.user_real

		if is_burning_tower:
			var damage_bonus_text: String = Utils.format_float(b.user_real, 0)
			attacker.get_player().display_small_floating_text(damage_bonus_text, b.get_buffed_unit(), Color8(255, 90, 0), 40.0)

		b.refresh_duration()


# Does damage to all units around the buffed unit, if the buffed unit dies
# b.userInt: AOE damage of the current buff.
# NOTE: explodeOnDeath() in original script
func burning_bt_on_death(event: Event):
	var b: Buff = event.get_buff()
	var killer: Unit = event.get_target()
	var buffed_unit: Unit = b.get_buffed_unit()
	Effect.create_simple_at_unit("res://src/effects/firelord_death_explode.tscn", buffed_unit)
	killer.do_spell_damage_aoe_unit(buffed_unit, 200, b.user_int, killer.calc_spell_crit_no_bonus(), 0.0)


func tower_init():
#   This buff is configurated as follows:
#   level: damage gain per attack
#   userReal: Already done bonus damage on the buffed unit
#   userInt: AOE-Damage if the buffed unit dies
	burning_bt = BuffType.new("burning_bt", 0.0, 0.0, false, self)
	burning_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	burning_bt.add_event_on_create(burning_bt_on_create)
	burning_bt.add_event_on_damaged(burning_bt_on_damaged)
	burning_bt.add_event_on_death(burning_bt_on_death)

	burning_bt.set_buff_tooltip(tr("MBB6"))


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower_level: int = tower.get_level()
	var target: Unit = event.get_target()
	var level: float = _stats.bonus_damage + tower_level * _stats.bonus_damage_add
	var duration: float = 5 + tower_level * 0.12
	var b: Buff = burning_bt.apply_custom_timed(tower, target, int(level * 100), duration)

#	Upgrade AOE-damage, if it makes sense
	if b.user_int < _stats.explode_damage:
		b.user_int = _stats.explode_damage
