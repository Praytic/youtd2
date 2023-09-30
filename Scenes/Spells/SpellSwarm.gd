extends SpellDummy


# This spell implements the "Carrion Swarm" spell from WC3.
# Deals damage in a cone from caster to target. Works as a
# moving AoE which expands as it gets closer to target.

# TODO: improve visuals

# TODO: make this spell deal damage the same way as in
# original youtd. Current implementation is a barebones
# approximation.


const MOVE_PERIOD: float = 0.2
const MOVE_SPEED_BASE: float = 150.0
const MOVE_ACCELERATION: float = 100.0

var _current_swarm_pos: Vector2
var _current_move_speed: float = MOVE_SPEED_BASE
var _already_damaged_list: Array[Unit] = []

# Spell data
var _damage: float
var _start_radius: float
var _end_radius: float

@export var _move_timer: Timer


func _ready():
	super()

	_current_swarm_pos = position


func _on_move_timer_timeout():
#	Move current position of spell
	_current_swarm_pos = Isometric.vector_move_toward(_current_swarm_pos, _target_position, _current_move_speed)
	_current_move_speed += MOVE_ACCELERATION

# 	Add visual effect
	var effect: int = Effect.create_animated("res://Scenes/Effects/GenericMagic.tscn", _current_swarm_pos.x, _current_swarm_pos.y, 0.0, 0.0)
	var effect_scale: float = _get_effect_scale()
	Effect.scale_effect(effect, effect_scale)
	Effect.destroy_effect_after_its_over(effect)

# 	Deal damage
	var current_radius: float = _get_current_radius()
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), _current_swarm_pos, current_radius)

#	Deal damage once to each creep in path
	for already_damaged_creep in _already_damaged_list:
		if !Utils.unit_is_valid(already_damaged_creep):
			continue

		creep_list.erase(already_damaged_creep)

	for creep in creep_list:
		do_spell_damage(creep, _damage)
		_already_damaged_list.append(creep)

	var reached_target: bool = _current_swarm_pos == _target_position
	
	if reached_target:
		_move_timer.stop()


func _get_move_progress() -> float:
	var start_pos: Vector2 = position
	var distance_travelled: float = Isometric.vector_distance_to(_current_swarm_pos, start_pos)
	var total_distance: float = Isometric.vector_distance_to(start_pos, _target_position)
	var move_progress: float = distance_travelled / total_distance

	return move_progress


func _get_effect_scale() -> float:
	var move_progress: float = _get_move_progress()
	var effect_scale: float = lerp(0.5, 1.5, move_progress)

	return effect_scale


func _get_current_radius() -> float:
	var move_progress: float = _get_move_progress()
	var current_radius: float = lerp(_start_radius, _end_radius, move_progress)

	return current_radius


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(data: Cast.SpellData):
	_damage = data.swarm.damage
	_start_radius = data.swarm.start_radius
	_end_radius = data.swarm.end_radius
