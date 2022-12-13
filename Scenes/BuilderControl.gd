extends Control

onready var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
onready var cam: Camera2D = get_tree().current_scene.get_node("DefaultCamera")
onready var map: TileMap = get_tree().current_scene.get_node("DefaultMap").get_node("Ground")
onready var towers: Node2D = get_tree().current_scene.get_node("Towers")
var build_mode: bool
var tower_preview_pos: Vector2
var buildable: bool

func _ready():
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])

func _unhandled_input(event):
	if event.is_action_released("ui_cancel") and build_mode == true:
		print("ui_cancel")
		cancel_build_mode()
	elif event.is_action_released("ui_accept") and build_mode == true:
		print("ui_accept")
		verify_and_build()
		cancel_build_mode()

func initiate_build_mode(tower_type: String):
	if build_mode:
		cancel_build_mode()
	build_mode = true
	set_tower_preview(tower_type)
	$TowerPreview/DragTower.build_init()

func verify_and_build():
	var tower_preview = $TowerPreview
	var tower_type = tower_preview.get_meta("type")
	if build_mode and buildable:
		print("Build tower %s at %s" % [tower_type, tower_preview_pos])
		var drag_tower = load("res://Scenes/Towers/" + tower_type + ".tscn").instance()
		drag_tower.position = tower_preview_pos
		towers.add_child(drag_tower, true)
		drag_tower.emit_signal("build_complete")
	else:
		print("Can't build tower %s at %s" % [tower_type, tower_preview_pos])

func cancel_build_mode():
	build_mode = false
	var tower_preview = $TowerPreview
	if not tower_preview.is_queued_for_deletion(): 
		tower_preview.free()

func set_tower_preview(tower_type):
	var drag_tower = load("res://Scenes/Towers/" + tower_type + ".tscn").instance()
	drag_tower.set_name("DragTower")
	drag_tower.modulate = Color("ab54ff3c")
	
	var control = Control.new()
	control.add_child(drag_tower)
	control.set_name("TowerPreview")
	control.set_meta("type", tower_type)
	add_child(control, true)
	move_child(get_node("TowerPreview"), 0)
	
	return control

func update_tower_preview():
	if tower_preview_pos:
		$TowerPreview.rect_position = tower_preview_pos
	if buildable:
		$TowerPreview/DragTower.modulate = Color("ad54ff3c")
	else:
		$TowerPreview/DragTower.modulate = Color("adff4545")
	update()

func _physics_process(delta):
	
	if build_mode:
		tower_preview_pos = CameraManager.get_tile_pos_on_cam(cam, map)
		if space.intersect_point(cam.get_global_mouse_position(), 1):
			buildable = false
		else:
			buildable = true
		update_tower_preview()
	
