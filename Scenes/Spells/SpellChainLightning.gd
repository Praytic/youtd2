extends SpellDummy

const CHAIN_DISTANCE: float = 300.0
const VISUAL_LIFETIME: float = 0.4
const VISUAL_COLOR: Color = Color.SKY_BLUE
const VISUAL_PATH: String = "res://Resources/Sprites/LightningAnimation.tscn"

var _damage: float = 0.0
var _damage_reduction: float = 0.0
var _chain_count: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	var hit_list: Array[Unit] = _get_hit_list()

#	Add visual for chain lightning
	var unit_list_for_visual: Array[Unit] = hit_list.duplicate()
	var caster: Unit = get_caster()
	unit_list_for_visual.insert(0, caster)
	
	for i in range(0, unit_list_for_visual.size() - 1):
		var start_unit: Unit = unit_list_for_visual[i]
		var end_unit: Unit = unit_list_for_visual[i + 1]
		_create_lightning_section(start_unit, end_unit)
	
# 	Apply damage
#	NOTE: do this after creating visuals in case
#	we kill one of the units
	for i in range(0, hit_list.size()):
		var unit: Unit = hit_list[i]
		var current_damage_reduction = max(0, 1.0 - _damage_reduction * i)
		var current_damage: float = _damage * current_damage_reduction

		do_spell_damage(unit, current_damage)


func _get_hit_list() -> Array[Unit]:
	var hit_unit_list: Array[Unit] = []
	var current_position: Vector2 = _target_position

	for i in range(0, _chain_count):
		var unit_list: Array[Unit] = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), current_position, CHAIN_DISTANCE)

		for unit in hit_unit_list:
			unit_list.erase(unit)

		if unit_list.is_empty():
			break

		Utils.sort_unit_list_by_distance(unit_list, current_position)

		var hit_unit: Unit = unit_list[0]
		hit_unit_list.append(hit_unit)
		current_position = hit_unit.position
	
	return hit_unit_list


func _create_lightning_section(start_unit: Unit, end_unit: Unit):
	var interpolated_sprite: InterpolatedSprite = InterpolatedSprite.create_between_units(VISUAL_PATH, VISUAL_LIFETIME, start_unit, end_unit)
	interpolated_sprite.z_index = 1000

	interpolated_sprite.modulate = VISUAL_COLOR.darkened(0.8)

	var modulate_tween = create_tween()
	modulate_tween.tween_property(interpolated_sprite, "modulate",
		VISUAL_COLOR,
		0.1 * VISUAL_LIFETIME)
	modulate_tween.tween_property(interpolated_sprite, "modulate",
		Color.TRANSPARENT,
		0.1 * VISUAL_LIFETIME).set_delay(0.8 * VISUAL_LIFETIME)

	Utils.add_object_to_world(interpolated_sprite)


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(data: Cast.SpellData):
	_damage = data.chain_lightning.damage
	_damage_reduction = data.chain_lightning.damage_reduction
	_chain_count = data.chain_lightning.chain_count
