extends Tower


# TODO: original script calls display_small_floating_text on
# attacker.getOwner() object but currently owner-specific
# floating text isn't implemented


var natac_burning_buff: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bonus_damage = 1.0, bonus_damage_add = 0.10, explode_damage = 49},
		2: {bonus_damage = 2.5, bonus_damage_add = 0.25, explode_damage = 277},
		3: {bonus_damage = 4.0, bonus_damage_add = 0.40, explode_damage = 750},
		4: {bonus_damage = 5.5, bonus_damage_add = 0.55, explode_damage = 1875},
	}


func get_extra_tooltip_text() -> String:
	var bonus_damage: String = String.num(_stats.bonus_damage, 2)
	var bonus_damage_other: String = String.num(_stats.bonus_damage * 0.3, 2)
	var explode_damage: String = String.num(_stats.explode_damage, 2)
	var bonus_damage_add: String = String.num(_stats.bonus_damage_add, 2)
	var bonus_damage_add_other: String = String.num(_stats.bonus_damage_add * 0.3, 2)

	var text: String = ""

	text += "[color=GOLD]Burn[/color]\n"
	text += "Starts to burn a target. On every further hit of a fire tower, the target will receive more bonus damage then before. Burning Structures will increase the bonus damage by %s, any other fire towers by %s. If the unit dies, it explodes and deals %s damage to nearby units in a range of 200.\n" % [bonus_damage, bonus_damage_other, explode_damage]
	text += "Lasts 5 seconds after the last attack of a fire tower.\n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s damage gain (Burning Structrues)\n" % bonus_damage_add
	text += "+%s damage gain (Other fire towers)\n" % bonus_damage_add_other
	text += "+0.12 seconds burn duration"

	return text


# b.userReal: The user Real is the current bonus damage of the buff. Init with 0
func init_on_create(event: Event):
	var b: Buff = event.get_buff()
	b.user_real = 0.0
	b.user_int = 0


# Increase damage gain and do direct damage to the target by setting the event damage
func damage_on_fire_attack(event: Event):
	var b: Buff = event.get_buff()

	var damage_gain: float
	var damage_factor: float
	var attacker: Unit = event.get_target()
	var is_burning_tower: bool

	if Element.enm.FIRE == attacker.get_category():
		is_burning_tower = (attacker as Tower).get_family() == (b.get_caster() as Tower).get_family()

		if is_burning_tower:
			damage_factor = 1.0
		else:
			damage_factor = 0.3

		damage_gain = damage_factor * b.get_level() * 0.01
		b.user_real = b.user_real + damage_gain
		event.damage = event.damage + b.user_real

		if is_burning_tower:
			attacker.getOwner().display_small_floating_text(str(int(b.user_real)), b.get_buffed_unit(), 255, 90, 0, 40.0)

		b.refresh_duration()


# Does damage to all units around the buffed unit, if the buffed unit dies
# b.userInt: AOE damage of the current buff.
func explode_on_death(event: Event):
	var b: Buff = event.get_buff()
	var killer: Unit = event.get_target()
	var buffed_unit: Unit = b.get_buffed_unit()
	SFX.sfx_at_unit("Abilities\\Spells\\Other\\Incinerate\\FireLordDeathExplode.mdl", buffed_unit)	
	killer.do_spell_damage_aoe_unit(buffed_unit, 200, b.user_int, killer.calc_spell_crit_no_bonus(), 0.0)


func tower_init():
#   This buff is configurated as follows:
#   level: damage gain per attack
#   userReal: Already done bonus damage on the buffed unit
#   userInt: AOE-Damage if the buffed unit dies
	natac_burning_buff = BuffType.new("natac_burning_buff", 0.0, 0.0, false, self)
	natac_burning_buff.set_buff_icon("@@0@@")
	natac_burning_buff.add_event_on_create(init_on_create)
	natac_burning_buff.add_event_on_damaged(damage_on_fire_attack)
	natac_burning_buff.add_event_on_death(explode_on_death)

	natac_burning_buff.set_buff_tooltip("Burning Structures\nThis unit is Burning; it will receive more damage from fire towers. If this unit dies while still burning, it will explode dealing damage to nearby units.")


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_damage)


func on_damage(event: Event):
	var tower: Tower = self

	var tower_level: int = tower.get_level()
	var target: Unit = event.get_target()
	var level: float = _stats.bonus_damage + tower_level * _stats.bonus_damage_add
	var duration: float = 5 + tower_level * 0.12
	var b: Buff = natac_burning_buff.apply_custom_timed(tower, target, int(level * 100), duration)

#	Upgrade AOE-damage, if it makes sense
	if b.user_int < _stats.explode_damage:
		b.user_int = _stats.explode_damage
