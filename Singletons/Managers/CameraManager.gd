extends Node

# Returns the position of the mouse clamped to 
# the underlying tile on the map
func get_tile_pos_on_cam(cam: Camera2D, map: TileMap) -> Vector2:
	var clamped_world_pos = get_mouse_pos_on_map_clamped(map)

	var camera_center_pos = cam.get_camera_screen_center()
	var screen_size = get_viewport().get_visible_rect().size
	var camera_pos = camera_center_pos - screen_size / 2
	var clamped_mouse_pos = clamped_world_pos - camera_pos
	
	return clamped_mouse_pos

func get_mouse_pos_on_map_clamped(map: TileMap) -> Vector2:
	var world_pos = map.get_local_mouse_position()
	var map_pos = map.world_to_map(world_pos)
	var clamped_world_pos = map.map_to_world(map_pos)

	return clamped_world_pos
