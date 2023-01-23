extends KinematicBody2D

class_name Mob


signal moved(delta)
signal dead


export var health_max: int = 100
export var health: int = 100
export var default_mob_move_speed: int = 500
var mob_move_speed: int


var path_curve: Curve2D
var current_path_index: int = 0


onready var _sprite = $Sprite


func _ready():
	mob_move_speed = default_mob_move_speed


func _process(delta):
	var path_point: Vector2 = path_curve.get_point_position(current_path_index)
	position = position.move_toward(path_point, mob_move_speed * delta)
	emit_signal("moved", delta)
	
	var reached_path_point: bool = (position == path_point)
	
	if reached_path_point:
		current_path_index += 1

		#		Delete mob once it has reached the end of the path
		var reached_end_of_path: bool = (current_path_index >= path_curve.get_point_count())

		if reached_end_of_path:
			die()
			return
		
		var mob_animation: String = get_mob_animation()
		_sprite.play(mob_animation)


func change_health(damage):
	health += damage
	
	$HealthBar.set_as_ratio(float(health) / float(health_max))
	if health < 0:
		die()


func set_path(path: Path2D):
	path_curve = path.curve
	position = path_curve.get_point_position(0)


func get_mob_animation() -> String:
	var path_point: Vector2 = path_curve.get_point_position(current_path_index)
	var move_direction: Vector2 = path_point - position
	var move_angle: float = rad2deg(move_direction.angle())

#	NOTE: the actual angles for 4-directional isometric movement are around
#   +- 27 degrees from x axis but checking for which quadrant the movement vector
#	falls into works just as well
	if 0 < move_angle && move_angle < 90:
		return "run_e"
	elif 90 < move_angle && move_angle < 180:
		return "run_s"
	elif -180 < move_angle && move_angle < -90:
		return "run_w"
	elif -90 < move_angle && move_angle < 0:
		return "run_n"
	else:
		return "stand"

func die():
	emit_signal("dead")
	queue_free()


func add_aura_list(aura_info_list: Array):
	for aura_info in aura_info_list:
		var aura = Aura.new(aura_info)
		aura.connect("applied", self, "on_aura_applied")
		aura.connect("expired", self, "on_aura_expired")
		$AuraContainer.add_child(aura)

		if aura.is_poison():
			process_poison_auras(aura.type)
		else:
			aura.run()


# Poison aura's have special stacking behavior. If
# multiple poison auras of same type are added, then only
# the strongest aura will be running. Other aura's will be
# paused until the strongest aura expires. Note that if a
# stronger aura is added while another aura is running, the
# stronger one will take over. Note that auras are compared
# by DPS, not by value!
func process_poison_auras(type: String):
	var aura_list: Array = get_aura_list()

	var strongest_aura: Aura = null
	var running_aura: Aura = null
	
	for aura in aura_list:
		if aura.type != type:
			continue
		
		var this_dps: float = aura.get_dps()

		if strongest_aura != null:
			if this_dps > strongest_aura.get_dps():
				strongest_aura = aura
		else:
			strongest_aura = aura

		if aura.is_running:
			running_aura = aura

	if running_aura == null:
		if strongest_aura != null:
			strongest_aura.run()
	else:
		if running_aura != strongest_aura:
			running_aura.pause()
			strongest_aura.run()


# Status auras of the same type run and expire in parallel.
# Only the strongest aura of type has an effect. For
# example, if there are multiple slow aura's, then final
# slow effect will be equal to the strongest slow aura.
func process_status_auras(type: String):
	var aura_list: Array = get_aura_list()

	var strongest_aura: Aura = null
	
	for aura in aura_list:
		if aura.type != type:
			continue
		
		var this_value: float = aura.get_value()

		if strongest_aura != null:
			if this_value > strongest_aura.get_value():
				strongest_aura = aura
		else:
			strongest_aura = aura

	match type:
		"slow":
			if strongest_aura != null:
				mob_move_speed = default_mob_move_speed - strongest_aura.get_value()
			else:
				mob_move_speed = default_mob_move_speed
		"change health": return
		_: print_debug("unhandled aura.type in process_status_auras():", type)


func on_aura_applied(aura: Aura):
	if aura.is_status():
		process_status_auras(aura.type)

	match aura.type:
		"change health": change_health(aura.get_value())
		"slow": return
		_: print_debug("unhandled aura.type in on_aura_applied():", aura.type)


func on_aura_expired(aura: Aura):
	if aura.is_poison():
		process_poison_auras(aura.type)

	if aura.is_status():
		process_status_auras(aura.type)


# Get list of active aura's (including paused)
func get_aura_list() -> Array:
	var aura_list: Array = []

	for aura_node in $AuraContainer.get_children():
		if !(aura_node is Aura):
			continue
		
		var aura: Aura = aura_node as Aura
		
		if aura.is_expired:
			continue

		aura_list.append(aura)

	return aura_list
