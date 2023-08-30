class_name Iterate


# Iterate is a wrapper over get_units_in_range() f-n which
# stores the resulting unit list and allows iterating over
# units.


var _next_list: Array[Unit] = []


func _init(center_pos: Vector2, target_type: TargetType, radius: float):
	_next_list = Utils.get_units_in_range(target_type, center_pos, radius)


# NOTE: Iterate.overUnitsInRangeOf() in JASS
static func over_units_in_range_of(_caster: Unit, target_type: TargetType, x: float, y: float, radius: float) -> Iterate:
	var center_pos: Vector2 = Vector2(x, y)
	var it: Iterate = Iterate.new(center_pos, target_type, radius)

	return it


# NOTE: Iterate.overUnitsInRangeOfCaster() in JASS
static func over_units_in_range_of_caster(caster: Unit, target_type: TargetType, radius: float) -> Iterate:
	var center_pos: Vector2 = caster.position
	var it: Iterate = Iterate.new(center_pos, target_type, radius)

	return it


# NOTE: Iterate.overUnitsInRangeOfUnit() in JASS
static func over_units_in_range_of_unit(_caster: Unit, target_type: TargetType, center: Unit, radius: float) -> Iterate:
	var center_pos: Vector2 = center.position
	var it: Iterate = Iterate.new(center_pos, target_type, radius)

	return it


# NOTE: iterate.next() in JASS
func next() -> Unit:
	_remove_invalid_units()

	var next_unit: Unit

	if !_next_list.is_empty():
		next_unit = _next_list.pop_front()
	else:
		next_unit = null

	return next_unit


# NOTE: iterate.nextRandom() in JASS
func next_random() -> Unit:
	_remove_invalid_units()
	
	var next_unit: Unit

	if !_next_list.is_empty():
		next_unit = _next_list.pick_random()
	else:
		next_unit = null

	return next_unit


# NOTE: Original API has this f-n but in Godot Iterate will
# get cleaned up automatically. Leave it as a stub to call
# in tower scripts.
# NOTE: iterate.destroy() in JASS
func destroy():
	pass


# NOTE: iterate.count() in JASS
func count() -> int:
	return _next_list.size()


# NOTE: need to remove invalid units before each call to
# next() because units may be killed or removed from the
# game while Iterate is used.
func _remove_invalid_units():
	_next_list = _next_list.filter(
		func(unit) -> bool:
			var unit_is_valid: bool = Utils.unit_is_valid(unit)

			return unit_is_valid
	)
