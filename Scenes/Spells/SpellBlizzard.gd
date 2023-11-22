extends SpellDummy

const WAVE_INTERVAL: float = 1.0

var _damage: float = 0.0
var _radius: float = 0.0
var _wave_count: int = 0

var _completed_wave_count: int = 0

@export var _particles: CPUParticles2D
@export var _wave_timer: Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	_wave_timer.start(WAVE_INTERVAL)

#	NOTE: do first wave on creation
	_on_wave_timer_timeout()

#	Move particles emitter so that they are above target position
	_particles.position += _target_position - position


func _on_wave_timer_timeout():
	do_spell_damage_aoe(_target_position, _radius, _damage)

	_completed_wave_count += 1

	var all_waves_done: bool = _completed_wave_count >= _wave_count
	if all_waves_done:
		_wave_timer.stop()
		_particles.set_emitting(false)


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(data: SpellType.SpellData):
	_damage = data.blizzard.damage
	_radius = data.blizzard.radius
	_wave_count = data.blizzard.wave_count
