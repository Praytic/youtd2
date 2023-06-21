class_name Iterate


enum NextOrder {
	FRONT,
	RANDOM,
}


var _caster: Unit
var _center_unit: Unit
var _center_pos: Vector2
var _target_type: TargetType
var _radius: float
var _next_list: Array[Unit] = []
var _already_returned_list: Array[Unit] = []


static func over_units_in_range_of(caster: Unit, target_type: TargetType, x: float, y: float, radius: float) -> Iterate:
	var it: Iterate = Iterate.new()
	it._caster = caster
	it._center_unit = null
	it._center_pos = Vector2(x, y)
	it._target_type = target_type
	it._radius = radius

	return it


static func over_units_in_range_of_caster(caster: Unit, target_type: TargetType, radius: float) -> Iterate:
	var it: Iterate = Iterate.new()
	it._caster = caster
	it._center_unit = caster
	it._center_pos = Vector2.ZERO
	it._target_type = target_type
	it._radius = radius

	return it


static func over_units_in_range_of_unit(caster: Unit, target_type: TargetType, center: Unit, radius: float) -> Iterate:
	var it: Iterate = Iterate.new()
	it._caster = caster
	it._center_unit = center
	it._center_pos = Vector2.ZERO
	it._target_type = target_type
	it._radius = radius

	return it


func next() -> Unit:
	var unit: Unit = _next_internal(NextOrder.FRONT)

	return unit


func next_random() -> Unit:
	var unit: Unit = _next_internal(NextOrder.RANDOM)

	return unit


# NOTE: Original API has this f-n but in Godot Iterate will
# get cleaned up automatically. Leave it as a stub to call
# in tower scripts.
func destroy():
	pass


func count() -> int:
	return _next_list.size()


func _next_internal(next_order: NextOrder) -> Unit:
#   NOTE: some tower scripts use Iterate together with
#   sleeping so calls to next() may happen with a delay.
#   Therefore we need consider that mobs may move between
#   calls to next().

#	Remove units that went out of range
	_next_list = _next_list.filter(
		func(unit: Unit) -> bool:
			var distance: float = Isometric.vector_distance_to(_get_center_pos(), unit.position)
			var unit_is_in_range: bool = distance < _radius

			if !unit_is_in_range:
				return false

			return true
	)

# 	If ran out units, add units that entered into range
	if _next_list.is_empty():
		var units_in_range: Array[Unit] = Utils.get_units_in_range(_target_type, _get_center_pos(), _radius)

		for unit in units_in_range:
			var unit_already_returned: bool = _already_returned_list.has(unit)

			if !unit_already_returned:
				_next_list.append(unit)

	if !_next_list.is_empty():
		var next_unit: Unit

		match next_order:
			NextOrder.FRONT:
				next_unit = _next_list.pop_front()
			NextOrder.RANDOM:
				next_unit = _next_list.pick_random()

		_already_returned_list.append(next_unit)

		return next_unit
	else:
		return null


func _get_center_pos() -> Vector2:
	if _center_unit != null:
		return _center_unit.position
	else:
		return _center_pos
