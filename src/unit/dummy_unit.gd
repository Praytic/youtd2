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
var _cleanup_done: bool = false
var _position_wc3: Vector3


#########################
###     Built-in      ###
#########################

func _ready():
	_caster.tree_exited.connect(_on_caster_tree_exited)


#########################
###       Public      ###
#########################

func set_position_wc3(value: Vector3):
	_position_wc3 = value
	position.x = Utils.to_pixels(_position_wc3.x)
	position.y = Utils.to_pixels(_position_wc3.y / 2)


func set_position_wc3_2d(value: Vector2):
	set_position_wc3(Vector3(value.x, value.y, get_z()))


func set_z(z: float):
	var new_position_wc3: Vector3 = Vector3(_position_wc3.x, _position_wc3.y, z)
	set_position_wc3(new_position_wc3)


func get_position_canvas() -> Vector2:
	return position


func get_position_wc3_2d() -> Vector2:
	var position_2d: Vector2 = Vector2(_position_wc3.x, _position_wc3.y)

	return position_2d


func get_position_wc3() -> Vector3:
	return _position_wc3


# NOTE: unit.getX() in JASS
func get_x() -> float:
	return _position_wc3.x


# NOTE: unit.getY() in JASS
func get_y() -> float:
	return _position_wc3.y


# NOTE: unit.getZ() in JASS
func get_z() -> float:
	return _position_wc3.z


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
func do_spell_damage_aoe(center: Vector2, radius: float, damage: float, sides_ratio: float):
	var creep_list: Array = Utils.get_units_in_range(_caster, TargetType.new(TargetType.CREEPS), center, radius)

	for creep in creep_list:
		var damage_for_creep: float = Utils.get_aoe_damage(center, creep, radius, damage, sides_ratio)
		do_spell_damage(creep, damage_for_creep)


# Deals aoe damage from the position of the dummy unit
# NOTE: dummyUnit.doSpellDamagePBAoE() in JASS
func do_spell_damage_pb_aoe(radius: float, damage: float, sides_ratio: float):
	var center: Vector2 = get_position_wc3_2d()
	do_spell_damage_aoe(center, radius, damage, sides_ratio)


# NOTE: you must call this instead of queue_free(), so that
# tree_exited() signal is emitted immediately
func remove_from_game():
	var parent: Node = get_parent()

	if parent != null && is_inside_tree():
		parent.remove_child(self)

	queue_free()


#########################
###      Private      ###
#########################

func _cleanup():
	if _cleanup_done:
		return

	_cleanup_done = true

#	NOTE: cleanup handler is valid only in Projectile
#	subclass
	if _cleanup_handler.is_valid():
		_cleanup_handler.call(self)

	remove_from_game()


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
	var dmg_to_size_mod: float = _caster.get_damage_to_size(creep_size)
	var damage_bonus: float = _damage_bonus_to_size_map.get(creep_size, 0.0)
	var mod_for_size: float = 1.0 + Utils.divide_safe(damage_bonus, dmg_to_size_mod)

	return mod_for_size


#########################
###     Callbacks     ###
#########################

func _on_caster_tree_exited():
	_cleanup()


#########################
### Setters / Getters ###
#########################

func get_caster() -> Unit:
	return _caster


# NOTE: dummyUnit.setDamageEvent() in JASS
func set_damage_event(handler: Callable):
	_damage_event_handler = handler


# NOTE: dummyUnit.setKillEvent() in JASS
func set_kill_event(handler: Callable):
	_kill_event_handler = handler


func get_dmg_ratio() -> float:
	return _damage_ratio


func get_crit_ratio() -> float:
	return _crit_ratio
