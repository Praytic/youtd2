extends Node


signal room_id_changed()

var _room_id: int : get = get_room_id, set = set_room_id


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func get_room_id() -> int:
	return _room_id


func set_room_id(room_id: int):
	_room_id = room_id
	room_id_changed.emit()

func generate_room_id():
	_room_id = 12345
	room_id_changed.emit()
