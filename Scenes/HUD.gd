extends Control


signal start_wave(wave_index)
signal stop_wave()

var global_mouse_pos = Vector2.ZERO
var local_mouse_pos = Vector2.ZERO
var cam_global_mouse_pos = Vector2.ZERO
var cam_local_mouse_pos = Vector2.ZERO
var world_to_map_tile_global_pos = Vector2.ZERO
var world_to_map_tile_local_pos = Vector2.ZERO
var world_to_map_tile_cam_global_pos = Vector2.ZERO
var world_to_map_tile_cam_local_pos = Vector2.ZERO
var map_to_world_global_pos = Vector2.ZERO
var map_to_world_local_pos = Vector2.ZERO
var map_to_world_cam_global_pos = Vector2.ZERO
var map_to_world_cam_local_pos = Vector2.ZERO
var color = Color.white


func set_tower_preview(tower_type, mouse_position) -> Control:
	var drag_tower = load("res://Scenes/Towers/" + tower_type + ".tscn").instance()
	drag_tower.set_name("DragTower")
	drag_tower.modulate = Color("ab54ff3c")
	
	var control = Control.new()
	control.add_child(drag_tower)
	control.rect_position = mouse_position
	control.set_name("TowerPreview")
	control.set_meta("type", tower_type)
	add_child(control, true)
	move_child(get_node("TowerPreview"), 0)
	
	return control

func update_tower_preview(new_pos, mouse_pos, color):
	print("Tile: %s | mouse_pos: %s" % [new_pos, mouse_pos])
	$TowerPreview.rect_position = new_pos + mouse_pos
	if $TowerPreview/DragTower.modulate != Color(color):
		$TowerPreview/DragTower.modulate = Color(color)

func _ready():
	pass

func _physics_process(delta):
	var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	var cam: Camera2D = get_tree().current_scene.get_node("DefaultCamera")
	var map = get_tree().current_scene.get_node("DefaultMap").get_node("Ground")
	global_mouse_pos = get_global_mouse_position()
	local_mouse_pos = get_local_mouse_position()
	cam_global_mouse_pos = cam.get_global_mouse_position()
	cam_local_mouse_pos = cam.get_local_mouse_position()
	world_to_map_tile_global_pos = map.world_to_map(global_mouse_pos)
	world_to_map_tile_local_pos = map.world_to_map(local_mouse_pos)
	world_to_map_tile_cam_global_pos = map.world_to_map(cam_global_mouse_pos)
	world_to_map_tile_cam_local_pos = map.world_to_map(cam_local_mouse_pos)
	map_to_world_global_pos = map.map_to_world(world_to_map_tile_global_pos)
	map_to_world_local_pos = map.map_to_world(world_to_map_tile_local_pos)
	map_to_world_cam_global_pos = map.map_to_world(world_to_map_tile_cam_global_pos)
	map_to_world_cam_local_pos = map.map_to_world(world_to_map_tile_cam_local_pos)
	update()
	if $TowerPreview != null:
		update_tower_preview(map_to_world_local_pos, cam_global_mouse_pos, color)

func _draw():
	draw_circle(global_mouse_pos, 10.0, Color.black)
	draw_circle(local_mouse_pos, 10.0, Color.green)
	draw_circle(cam_global_mouse_pos, 10.0, Color.blue)
	draw_circle(cam_local_mouse_pos, 10.0, Color.violet)
	draw_circle(world_to_map_tile_global_pos, 10.0, Color.red)
	draw_circle(world_to_map_tile_local_pos, 10.0, Color.white)
	draw_circle(world_to_map_tile_cam_global_pos, 10.0, Color.yellow)
	draw_circle(world_to_map_tile_cam_local_pos, 10.0, Color.gray)
	draw_circle(map_to_world_global_pos, 10.0, Color.brown)
	draw_circle(map_to_world_local_pos, 10.0, Color.orange)
	draw_circle(map_to_world_cam_global_pos, 10.0, Color.pink)
	draw_circle(map_to_world_cam_local_pos, 10.0, Color.teal)
	

func _on_StartWaveButton_pressed():
	var wave_index: int = $VBoxContainer/HBoxContainer/WaveEdit.value
	emit_signal("start_wave", wave_index)


func _on_StopWaveButton_pressed():
	emit_signal("stop_wave")

