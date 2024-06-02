@tool
class_name FreshnessIndicator extends Control


# Displays two moving particles around the border of an item
# button. Used to indicate when an item is "fresh", meaning
# that it just dropped. Using two particles so it looks
# different from auto mode indicator which has 4 particles.


var _cycle_timer: float = 0.0

@export var _particle_1: CPUParticles2D
@export var _particle_2: CPUParticles2D
	
@onready var _particle_list: Array[CPUParticles2D] = [
	_particle_1,
	_particle_2,
]


func _process(delta):
	if !visible:
		return
	
	_cycle_timer -= delta
	if _cycle_timer <= 0.0:
		_cycle_timer = AutoModeIndicator.CYCLE_DURATION
	
	AutoModeIndicator.update_border_particles(self, _particle_list, _cycle_timer, 0.5)
