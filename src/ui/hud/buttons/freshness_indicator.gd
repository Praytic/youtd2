@tool
class_name FreshnessIndicator extends Control


# Displays two moving particles around the border of an item
# button. Used to indicate when an item is "fresh", meaning
# that it just dropped. Using two particles so it looks
# different from auto mode indicator which has 4 particles.


@export var _particle_1: CPUParticles2D
@export var _particle_2: CPUParticles2D
	
@onready var _particle_list: Array[CPUParticles2D] = [
	_particle_1,
	_particle_2,
]


func _process(_delta: float):
	if !visible:
		return
	
	AutoModeIndicator.update_border_particles(self, _particle_list, 0.5)
