extends Path2D


@export var is_air: bool
@export var player: int
@export var z_points: Dictionary


var default_z = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	for z_point in z_points.keys():
		if curve.get_point_position(z_point) == Vector2.ZERO:
			push_error("Some z_point is assigned to non-existant Curve2D point. \
			Make sure you specify index of the existing Curve2D point.")


func get_start() -> Vector2:
	var my_curve: Curve2D = get_curve()
	return my_curve.get_point_in(0)
	

func get_z(path_point_id: int) -> int:
	if z_points.has(path_point_id):
		return default_z + z_points.get(path_point_id)
	else:
		return default_z
#test1
#test2
#test3
