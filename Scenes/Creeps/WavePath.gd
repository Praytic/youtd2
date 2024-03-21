class_name WavePath extends Path2D


@export var is_air: bool
@export var index: int


func _ready():
	add_to_group("wave_paths")
