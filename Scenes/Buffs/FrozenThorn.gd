class_name FrozenThorn
extends Buff

var _damage: float
var _damage_add: float

func _init(damage: float, damage_add: float):
	_damage = damage
	_damage_add = damage_add

	add_event_handler_with_chance(Buff.EventType.DAMAGE, self, "_on_damage", 0.15, 0.0)


func _on_damage(event: Event):
	if event.is_main_target && !event.target.is_immune():
		Utils.sfx_at_unit("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorDamage.mdl", event.target)

		_caster.do_spell_damage(event.target, 25 + _damage_add * _caster.get_level(), _caster.calc_spell_crit_no_bonus(), false)
