extends Control


class_name TowerPreview


var tilemap: TileMap
var cam: Camera2D

func _init(tilemap_arg: TileMap, cam_arg: Camera2D, tower_type):
	tilemap = tilemap_arg
	cam = cam_arg

	var drag_tower = load("res://Scenes/Towers/" + tower_type + ".tscn").instance()
	drag_tower.set_name("DragTower")
	drag_tower.modulate = Color("ab54ff3c")

	add_child(drag_tower)
	set_meta("type", tower_type)


func _ready():
	$DragTower.build_init()


# TODO: fix color changing, currently wrong
# maybe get_world_2d() for this node is offset?
func _process(delta):
	var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	var mouse_position = get_global_mouse_position()
	var cam_global_mouse_pos = cam.get_global_mouse_position()
	var tile_pos: Vector2 = tilemap.world_to_map(mouse_position)
	tile_pos = tilemap.map_to_world(tile_pos)
	if space.intersect_point(mouse_position, 1):
		$DragTower.modulate = Color("adff4545")
	else:
		$DragTower.modulate = Color("ad54ff3c")


func _physics_process(delta):
	var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	var cam: Camera2D = get_tree().current_scene.get_node("DefaultCamera")
	var map = get_tree().current_scene.get_node("DefaultMap").get_node("Ground")
	
	var world_pos = map.get_local_mouse_position()
	var map_pos = map.world_to_map(world_pos)
	var clamped_world_pos = map.map_to_world(map_pos)

	var camera_center_pos = cam.get_camera_screen_center()
	var viewport_size = get_viewport().size
	var camera_pos = camera_center_pos - viewport_size / 2
	var clamped_mouse_pos = clamped_world_pos - camera_pos
	

	rect_position = clamped_mouse_pos

	# if $TowerPreview/DragTower.modulate != Color(color):
	#     $TowerPreview/DragTower.modulate = Color(color)
