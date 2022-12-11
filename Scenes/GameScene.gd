extends Node2D

const mob_scene_map: Dictionary = {
	"Mob": preload("res://Scenes/Mob.tscn")
}


var map_node: Node
var build_mode: bool
var build_location: Vector2
var buildable: bool

func _ready():
	map_node = get_node("DefaultMap")
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])
	
	$Canvas/HUD/VBoxContainer/HBoxContainer/WaveEdit.value = 1
	$MobSpawner.start(1)

func _physics_process(delta: float):
	if build_mode:
		update_tower_preview()

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
		buildable = false
	else:
		get_node("Canvas").update_tower_preview(tile_pos, "ad54ff3c")
		buildable = true
	build_location = tile_pos
	
func verify_and_build():
	var tower_preview = get_node("Canvas/TowerPreview")
	var tower_type = tower_preview.get_meta("type")
	if build_mode and buildable:
		print("Build tower %s at %s" % [tower_type, build_location])
		var drag_tower = load("res://Scenes/Towers/" + tower_type + ".tscn").instance()
		drag_tower.position = build_location
		get_node("Towers").add_child(drag_tower, true)
	else:
		print("Can't build tower %s at %s" % [tower_type, build_location])

func cancel_build_mode():
	build_mode = false
	var tower_preview = get_node("Canvas/TowerPreview")
	if not tower_preview.is_queued_for_deletion(): 
		tower_preview.free()

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
		


func _on_MobSpawner_spawned(mob_name):
	var mob_scene = mob_scene_map[mob_name]
	var mob: Mob = mob_scene.instance()
	
	$MobPath1.add_child(mob)


func _on_StartWaveButton_pressed():
	var wave_index: int = $Canvas/HUD/VBoxContainer/HBoxContainer/WaveEdit.value
	$MobSpawner.start(wave_index)


func _on_StopWaveButton_pressed():
	$MobSpawner.stop()


func _on_MobSpawner_progress_changed(progress_string):
	$Canvas/HUD/VBoxContainer/WaveProgressLabel.text = progress_string
