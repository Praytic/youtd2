extends SpellDummy

const WAVE_INTERVAL: float = 1.0

var _damage: float = 0.0
var _radius: float = 0.0
var _wave_count: int = 0

var _completed_wave_count: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	var wave_timer: Timer = Timer.new()
	wave_timer.one_shot = false
	wave_timer.timeout.connect(on_wave_timer_timeout)
	add_child(wave_timer)
	wave_timer.start(WAVE_INTERVAL)

#	NOTE: do first wave on creation
	on_wave_timer_timeout()


func on_wave_timer_timeout():
	if _completed_wave_count >= _wave_count:
		return

	do_spell_damage_aoe(_target_position, _radius, _damage)

	_completed_wave_count += 1


# NOTE: subclasses override this to save data that is useful
# for them
func _set_subclass_data(data: Cast.SpellData):
	_damage = data.blizzard.damage
	_radius = data.blizzard.radius
	_wave_count = data.blizzard.wave_count
