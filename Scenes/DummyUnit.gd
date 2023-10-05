class_name DummyUnit extends Node2D

# Base class for Projectiles and SpellDummy. A simpler
# version of Unit that can't be buffed, has less events,
# etc.


var _caster: Unit = null
var _damage_ratio: float = 1.0
var _crit_ratio: float = 0.0
var _damage_event_handler: Callable = Callable()
var _kill_event_handler: Callable = Callable()
var _cleanup_handler: Callable = Callable()
var _damage_bonus_to_size_map: Dictionary = {}


func _ready():
	_caster.tree_exited.connect(_on_caster_tree_exited)


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
func do_spell_damage(target: Unit, damage: float):
#	NOTE: caster may become invalid if tower launches a
#	projectile and is then sold before projectile reaches
#	the target.
	var caster_is_valid: bool = Utils.unit_is_valid(_caster)
	if !caster_is_valid:
		return

	var size_mod: float = _get_mod_for_size(target)
	var damage_intermediate: float = damage * _damage_ratio * size_mod
	var damage_killed_unit: bool = _caster.do_spell_damage(target, damage_intermediate, _crit_ratio)

	if damage_killed_unit:
		if _kill_event_handler.is_valid():
			var killed_event: Event = Event.new(target)
			_kill_event_handler.call(killed_event, self)
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


func get_dmg_ratio() -> float:
	return _damage_ratio


func get_crit_ratio() -> float:
	return _crit_ratio


# Returns damage modifier based on custom damage table.
# Normally this will be just 1.0.
# 
# NOTE: this is a bit tricky because Unit._do_damage()
# applies tower's "dmg to size" modifier on top of this modifier.
# For example, if tower has DMG_TO_MASS = 0.3 and bonus damage
# in custom damage table is +95% then total damage should be
# 30%+95%=125%. For this, we need to divide the damage bonus
# by "dmg to size" mod.
# 0.95 / 0.3 = 3.166
# mod_for_size then equals = 1.0 + 3.166 = 4.166
# Then later, during final calculations the tower's size mod is applied:
# 4.166 * 0.3 = 1.25
# And we get the desired end result
func _get_mod_for_size(target: Unit) -> float:
	if !target is Creep:
		return 1.0

	var creep: Creep = target as Creep
	var creep_size: CreepSize.enm = creep.get_size()
	var dmg_to_size_mod: float = _caster._get_damage_mod_for_creep_size(creep)
	var damage_bonus: float = _damage_bonus_to_size_map.get(creep_size, 0.0)
	var mod_for_size: float = 1.0 + 1.0 / dmg_to_size_mod * damage_bonus

	return mod_for_size


func _on_caster_tree_exited():
	_cleanup()


func _cleanup():
	if is_queued_for_deletion():
		return

#	NOTE: cleanup handler is valid only in Projectile
#	subclass
	if _cleanup_handler.is_valid():
		_cleanup_handler.call(self)

	queue_free()
