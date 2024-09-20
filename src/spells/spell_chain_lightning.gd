extends SpellDummy

const CHAIN_DISTANCE: float = 300.0
const VISUAL_LIFETIME: float = 0.4
const VISUAL_COLOR: Color = Color.SKY_BLUE

var _damage: float = 0.0
var _damage_reduction: float = 0.0
var _chain_count: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	var hit_list: Array[Unit] = _get_hit_list()

	if hit_list.is_empty():
		return

#	Add visual for chain lightning
	var unit_list_for_visual: Array[Unit] = hit_list.duplicate()
	
#	NOTE: first chain needs to originate from the position
#	of the spell dummy NOT the caster. This is to correctly
#	handle target_cast_from_point() case.
	var origin_pos: Vector3 = get_position_wc3()
	var first_unit: Unit = hit_list[0]
	_create_lightning_section_from_pos(origin_pos, first_unit)

	for i in range(0, unit_list_for_visual.size() - 1):
		var start_unit: Unit = unit_list_for_visual[i]
		var end_unit: Unit = unit_list_for_visual[i + 1]
		_create_lightning_section(start_unit, end_unit)
	
# 	Apply damage
	for i in range(0, hit_list.size()):
		var unit: Unit = hit_list[i]
		var current_damage_reduction = max(0, 1.0 - _damage_reduction * i)
		var current_damage: float = _damage * current_damage_reduction

		do_spell_damage(unit, current_damage)


func _get_hit_list() -> Array[Unit]:
	var hit_unit_list: Array[Unit] = []
	var current_position: Vector2 = _target_position

	for i in range(0, _chain_count):
		var unit_list: Array[Unit] = Utils.get_units_in_range(_caster, TargetType.new(TargetType.CREEPS), current_position, CHAIN_DISTANCE)

		for unit in hit_unit_list:
			unit_list.erase(unit)

		if unit_list.is_empty():
			break

		Utils.sort_unit_list_by_distance(unit_list, current_position)

		var hit_unit: Unit = unit_list[0]
		hit_unit_list.append(hit_unit)
		current_position = hit_unit.get_position_wc3_2d()
	
	return hit_unit_list


func _create_lightning_section(start_unit: Unit, end_unit: Unit):
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, start_unit, end_unit)
	_setup_chain(interpolated_sprite)


func _create_lightning_section_from_pos(start_pos: Vector3, end_unit: Unit):
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.create_from_point_to_unit(InterpolatedSprite.LIGHTNING, start_pos, end_unit)
	_setup_chain(interpolated_sprite)
	_setup_chain(interpolated_sprite)


func _setup_chain(chain: InterpolatedSprite):
	chain.set_lifetime(VISUAL_LIFETIME)

	chain.modulate = VISUAL_COLOR.darkened(0.8)

	var modulate_tween = create_tween()
	modulate_tween.tween_property(chain, "modulate",
		VISUAL_COLOR,
		0.1 * VISUAL_LIFETIME)
	modulate_tween.tween_property(chain, "modulate",
		Color.TRANSPARENT,
		0.1 * VISUAL_LIFETIME).set_delay(0.8 * VISUAL_LIFETIME)


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(data: SpellType.SpellData):
	_damage = data.chain_lightning.damage
	_damage_reduction = data.chain_lightning.damage_reduction
	_chain_count = data.chain_lightning.chain_count
