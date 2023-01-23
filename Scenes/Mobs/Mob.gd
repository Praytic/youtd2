extends KinematicBody2D

class_name Mob


signal moved(delta)
signal dead


export var health_max: int = 10
export var health: int = 10
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
#		NOTE: important to connect before calling
#		add_child(), so because first signal can be emitted
#		when add_child() is called
		aura.connect("applied", self, "on_aura_applied")
		aura.connect("expired", self, "on_aura_expired")
		$AuraContainer.add_child(aura)


func on_aura_applied(aura: Aura):
	match aura.type:
		"change health": change_health(aura.get_value())
		"change speed": update_speed_auras()
		_: print_debug("unhandled aura.type in on_aura_applied():", aura.type)


func on_aura_expired(aura: Aura):
	match aura.type:
		"change health": return
		"change speed": update_speed_auras()
		_: print_debug("unhandled aura.type on_aura_expired():", aura.type)


func update_speed_auras():
	var strongest_negative: int = 0
	var strongest_positive: int = 0
	
	for aura_node in $AuraContainer.get_children():
		if !(aura_node is Aura):
			continue
		
		var aura: Aura = aura_node as Aura
		
		if aura.is_expired:
			continue
		
		if aura.type != "change speed":
			continue
		
		if aura.get_value() < strongest_negative:
			strongest_negative = int(aura.get_value())
		
		if aura.get_value() > strongest_positive:
			strongest_positive = int(aura.get_value())
	
	mob_move_speed = int(max(0, default_mob_move_speed + strongest_negative + strongest_positive))
