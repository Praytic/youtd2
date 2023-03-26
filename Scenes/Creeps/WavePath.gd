extends Path2D


@export var is_air: bool
@export var player: int


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func get_start() -> Vector2:
	var curve: Curve2D = get_curve()
	return curve.get_point_in(0)
	
