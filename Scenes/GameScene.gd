extends Node2D

var map_node: Node
var build_mode: bool
var build_location: Vector2

func _ready():
	map_node = get_node("DefaultMap")
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])

func _physics_process(delta: float):
	if build_mode:
		update_tower_preview()
	
func initiate_build_mode(tower_type: String):
	build_mode = true
	get_node("Canvas").set_tower_preview(tower_type, get_global_mouse_position())

# update tower preview based on collision map
func update_tower_preview():
	#var tile_pos: Vector2
	var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	var mouse_position = get_global_mouse_position()
	var tile_pos: Vector2 = map_node.get_node("Ground").world_to_map(mouse_position)
	tile_pos = map_node.get_node("Ground").map_to_world(tile_pos)
	if space.intersect_point(mouse_position, 1):
		get_node("Canvas").update_tower_preview(tile_pos, "adff4545")
		print("Tile at %s is unbuildable." % tile_pos)
	else:
		get_node("Canvas").update_tower_preview(tile_pos, "ad54ff3c")
		print("Tile at %s is buildable." % tile_pos)
	build_location = tile_pos
		

# update_tower_preview based on tile map
#func update_tower_preview2():
#	var mouse_position = get_global_mouse_position()
#	var builable = true
#	var tile_pos: Vector2
#	for i in get_tree().get_nodes_in_group("unbuildable"):
#		var tile = i.world_to_map(mouse_position)
#		tile_pos = i.map_to_world(tile)
#		if i.get_cellv(tile) != -1:
#			builable = false
#			break
#	if builable:
#		get_node("Canvas").update_tower_preview(tile_pos, "ad54ff3c")
#		print("Tile at %s is buildable." % tile_pos)
#		build_valid = true
#	else:
#		get_node("Canvas").update_tower_preview(tile_pos, "adff4545")
#		print("Tile at %s is unbuildable." % tile_pos)
#		build_valid = false
#	build_location = tile_pos
		
