class_name WavePath extends Path2D


@export var is_air: bool
@export var player_id: int


func _ready():
	add_to_group("wave_paths")
