extends SpellDummy

const WAVE_INTERVAL: float = 1.0

var _damage: float = 0.0
var _radius: float = 0.0
var _wave_count: int = 0

var _completed_wave_count: int = 0

@export var _particles: CPUParticles2D
@export var _wave_timer: ManualTimer


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	_wave_timer.start(WAVE_INTERVAL)

#	NOTE: do first wave on creation
	_on_wave_timer_timeout()

#	Move particles emitter so that they are above target position
	var particles_pos_wc3: Vector3 = Vector3(_target_position.x, _target_position.y, Constants.TILE_SIZE_WC3 * 6)
	var particles_pos_canvas: Vector2 = Utils.wc3_pos_to_canvas_pos(particles_pos_wc3)
	_particles.global_position = particles_pos_canvas


func _on_wave_timer_timeout():
	do_spell_damage_aoe(_target_position, _radius, _damage, 0.0)

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
