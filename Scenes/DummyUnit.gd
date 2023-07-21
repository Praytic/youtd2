class_name DummyUnit extends Node2D

# Base class for Projectiles and SpellDummy. A simpler
# version of Unit that can't be buffed, has less events,
# etc.


var _caster: Unit = null
var _damage_ratio: float = 1.0
var _crit_ratio: float = 0.0
var _damage_event_handler: Callable = Callable()
var _kill_event_handler: Callable = Callable()


func get_caster() -> Unit:
	return _caster


# NOTE: dummyUnit.setDamageEvent() in JASS
func set_damage_event(handler: Callable):
	_damage_event_handler = handler


# NOTE: dummyUnit.setKillEvent() in JASS
func set_kill_event(handler: Callable):
	_kill_event_handler = handler


# NOTE: dummyUnit.doSpellDamage() in JASS
# 
# NOTE: crit ratio is used directly, without doing a random
# roll because it's intended that tower does a random roll
# once and then passes the result to DummyUnit(Projectile or
# Spell). The DummyUnit then becomes crit or non-crit at the
# moment of creation and stays that way while it is alive.
func do_spell_damage(target: Unit, amount: float):
	var spell_damage: float = Unit.get_spell_damage(amount, _crit_ratio, _caster, target) * _damage_ratio

	var damage_killed_unit: bool = target.receive_damage(spell_damage)

	if damage_killed_unit:
		if _kill_event_handler.is_valid():
			var killed_event: Event = Event.new(target)
			_kill_event_handler.call(killed_event, self)

		target._killed_by_unit(_caster)
	else:
		if _damage_event_handler.is_valid():
			var damage_event: Event = Event.new(target)
			_damage_event_handler.call(damage_event, self)


# NOTE: dummyUnit.doSpellDamageAoE() in JASS
func do_spell_damage_aoe(center: Vector2, radius: float, damage: float):
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), center, radius)

	for creep in creep_list:
		do_spell_damage(creep, damage)


# Deals aoe damage from the position of the dummy unit
# NOTE: dummyUnit.doSpellDamagePBAoE() in JASS
func do_spell_damage_pb_aoe(radius: float, damage: float, _mystery_float: float):
	var center: Vector2 = position
	do_spell_damage_aoe(center, radius, damage)
