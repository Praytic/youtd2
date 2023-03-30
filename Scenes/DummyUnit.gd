class_name DummyUnit extends Node2D

# Base class for Projectiles and SpellDummy. A simpler
# version of Unit that can't be buffed, has less events,
# etc.


signal dealt_damage(event: Event, dummy_unit: DummyUnit)
signal killed_unit(event: Event, dummy_unit: DummyUnit)


var _caster: Unit = null
var _damage_ratio: float = 1.0
var _crit_ratio: float = 0.0


static func make() -> DummyUnit:
	var dummy_unit_scene: PackedScene = load("res://Scenes/DummyUnit.tscn")
	var dummy_unit: DummyUnit = dummy_unit_scene.instantiate()

	return dummy_unit


func get_caster() -> Unit:
	return _caster


func set_damage_event(callable: Callable):
	dealt_damage.connect(callable)


func set_kill_event(callable: Callable):
	killed_unit.connect(callable)


# NOTE: crit ratio is used directly, without doing a random
# roll because it's intended that tower does a random roll
# once and then passes the result to DummyUnit(Projectile or
# Spell). The DummyUnit then becomes crit or non-crit at the
# moment of creation and stays that way while it is alive.
func do_spell_damage(target: Unit, amount: float):
	var spell_damage: float = Unit.get_spell_damage(amount, _crit_ratio, _caster, target) * _damage_ratio

	var damage_killed_unit: bool = target.receive_damage(spell_damage)

	if damage_killed_unit:
		var killed_event: Event = Event.new(target)
		killed_unit.emit(killed_event, self)
	else:
		var damage_event: Event = Event.new(target)
		dealt_damage.emit(damage_event, self)
