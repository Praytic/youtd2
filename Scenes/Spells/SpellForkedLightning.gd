extends SpellDummy


const AOE_DISTANCE: float = 400.0
const VISUAL_LIFETIME: float = 0.4
const VISUAL_COLOR: Color = Color.SKY_BLUE

var _damage: float = 0.0
var _target_count: int = 0


func _ready():
	super()

	if _target == null:
		push_error("Forked lightning must be cast on target. Casting on point is not supported.")
		
		return

	var hit_list: Array[Unit] = _get_hit_list()

#	Add visual for chain lightning
	var unit_list_for_visual: Array[Unit] = hit_list.duplicate()
	var caster: Unit = get_caster()
	unit_list_for_visual.insert(0, caster)
	
	for creep in hit_list:
		var start_unit: Unit = get_caster()
		var end_unit: Unit = creep
		_create_lightning_section(start_unit, end_unit)
	
# 	Apply damage
	for creep in hit_list:
		do_spell_damage(creep, _damage)


func _get_hit_list() -> Array[Unit]:
	var hit_unit_list: Array[Unit] = []
	hit_unit_list.append(_target)

	var it: Iterate = Iterate.over_units_in_range_of_caster(_target, TargetType.new(TargetType.CREEPS), AOE_DISTANCE)

	while true:
		var next: Unit = it.next_random()

		if next == null:
			break

		if next == _target:
			continue

		if hit_unit_list.size() == _target_count:
			break

		hit_unit_list.append(next)
	
	return hit_unit_list


func _create_lightning_section(start_unit: Unit, end_unit: Unit):
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, start_unit, end_unit)
	interpolated_sprite.set_lifetime(VISUAL_LIFETIME)

	interpolated_sprite.modulate = VISUAL_COLOR.darkened(0.8)

	var modulate_tween = create_tween()
	modulate_tween.tween_property(interpolated_sprite, "modulate",
		VISUAL_COLOR,
		0.1 * VISUAL_LIFETIME)
	modulate_tween.tween_property(interpolated_sprite, "modulate",
		Color.TRANSPARENT,
		0.1 * VISUAL_LIFETIME).set_delay(0.8 * VISUAL_LIFETIME)


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(data: SpellType.SpellData):
	_damage = data.forked_lightning.damage
	_target_count = data.forked_lightning.target_count
