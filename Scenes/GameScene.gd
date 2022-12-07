extends Node2D

var map_node: Node
var build_mode: bool
var build_valid: bool
var build_location: Vector2

func _ready():
	map_node = get_node("DefaultMap")
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])

func _process(delta):
	if build_mode:
		update_tower_preview()
	
func initiate_build_mode(tower_type):
	build_mode = true
	get_node("Canvas").set_tower_preview(tower_type, get_global_mouse_position())

func update_tower_preview():
	var mouse_position = get_global_mouse_position()
	for i in get_tree().get_nodes_in_group("unbuildable"):
		var tile = i.world_to_map(mouse_position)
		var tile_pos = i.map_to_world(tile)
		if i.get_cellv(tile) == -1:
			get_node("Canvas").update_tower_preview(tile_pos, "ad54ff3c")
			build_valid = true
			build_location = tile_pos
		else:
			get_node("Canvas").update_tower_preview(tile_pos, "adff4545")
			build_valid = false
