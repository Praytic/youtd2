extends Control


signal start_wave(wave_index)
signal stop_wave()

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

func update_tower_preview(new_pos, color):
	$TowerPreview.rect_position = new_pos
	if $TowerPreview/DragTower.modulate != Color(color):
		$TowerPreview/DragTower.modulate = Color(color)

func _ready():
	pass

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
	
	update()
	if $TowerPreview != null:
		update_tower_preview(clamped_mouse_pos, color)
	

func _on_StartWaveButton_pressed():
	var wave_index: int = $VBoxContainer/HBoxContainer/WaveEdit.value
	emit_signal("start_wave", wave_index)


func _on_StopWaveButton_pressed():
	emit_signal("stop_wave")

