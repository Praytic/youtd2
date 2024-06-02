@tool
class_name AutoModeIndicator extends Control


# Displays 4 "comets" which move around the border of parent
# UI element. Should be used to display that autocast
# automatic mode is enabled.

# NOTE: ParticlesContainer node is needed to be able to hide
# particles without modifying "visible" property of the
# AutoModeIndicator itself. This way, the indicator can
# show/hide it's particles while the parent of the indicator
# can decide whether the indicator should be visible
# overall.


const CYCLE_DURATION: float = 3.0

var _autocast: Autocast = null
var _cycle_timer: float = 0.0

@export var _particles_container: Control
@export var _particles_1: CPUParticles2D
@export var _particles_2: CPUParticles2D
@export var _particles_3: CPUParticles2D
@export var _particles_4: CPUParticles2D


@onready var _particle_list: Array[CPUParticles2D] = [
	_particles_1,
	_particles_2,
	_particles_3,
	_particles_4,
]


func set_autocast(autocast: Autocast):
	_autocast = autocast


func _process(delta: float):
	if !Engine.is_editor_hint():
		_particles_container.visible = _autocast != null && _autocast.auto_mode_is_enabled()
	
	if !_particles_container.visible:
		return
	
	_cycle_timer -= delta
	if _cycle_timer <= 0.0:
		_cycle_timer = CYCLE_DURATION
	
	AutoModeIndicator.update_border_particles(self, _particle_list, _cycle_timer, 0.25)


static func update_border_particles(parent_control: Control, particle_list: Array[CPUParticles2D], cycle_timer: float, border_ratio_per_particle: float):
	var particle_area_size: Vector2 = parent_control.size
	var particle_area_perimeter: float = 2 * (particle_area_size.x + particle_area_size.y)
	
	var distance_ratio_base: float = (1.0 - cycle_timer / CYCLE_DURATION)
	
	for i in range(0, particle_list.size()):
		var particle: CPUParticles2D = particle_list[i]
		var distance_ratio: float = distance_ratio_base + border_ratio_per_particle * i
		var travel_distance: float = particle_area_perimeter * distance_ratio
		
		var current_direction: Vector2 = Vector2(1, 0)
		
		var particle_pos: Vector2 = Vector2(0, 0)
		while travel_distance > 0:
			var travel_vector: Vector2 = current_direction * travel_distance
			travel_vector = travel_vector.clamp(-particle_area_size, particle_area_size)
			particle_pos += travel_vector
			travel_distance -= travel_vector.length()
			
			current_direction = current_direction.rotated(deg_to_rad(90))

		particle.position = particle_pos
