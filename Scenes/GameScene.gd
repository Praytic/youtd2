extends Node2D

const mob_scene_map: Dictionary = {
	"Mob": preload("res://Scenes/Mob.tscn")
}

var build_mode: bool
var mobs_exit_count: int = 0

export var mobs_game_over_count: int = 10
export var ignore_game_over: bool = true

func _ready():
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])
	
	$Canvas/HUD/VBoxContainer/HBoxContainer/WaveEdit.value = 1
	$MobSpawner.start(0)
	$MobSpawner.connect("wave_ended", self, "_on_wave_end")
	
	update_mob_exit_count(0)


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
	var tower_preview: TowerPreview = TowerPreview.new($DefaultMap/Ground, $DefaultCamera, tower_type)
	$Canvas/HUD.add_child(tower_preview)
	tower_preview.set_name("TowerPreview")


func get_build_pos() -> Vector2:
	var tilemap: TileMap = $DefaultMap/Ground
	
	var world_pos = get_global_mouse_position()
	var map_pos: Vector2 = tilemap.world_to_map(world_pos)
	var clamped_world_pos = tilemap.map_to_world(map_pos)

	return clamped_world_pos


func get_can_build(pos: Vector2) -> bool:
	var space: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	var mouse_position = get_global_mouse_position()

	var can_build = !space.intersect_point(mouse_position, 1)

	return can_build


func verify_and_build():
	var tower_preview = $Canvas/HUD/TowerPreview
	var tower_type = tower_preview.get_meta("type")

	var build_pos: Vector2 = get_build_pos()
	var can_build: bool = get_can_build(build_pos)

	if build_mode and can_build:
		print("Build tower %s at %s" % [tower_type, build_pos])
		var drag_tower = load("res://Scenes/Towers/" + tower_type + ".tscn").instance()
		drag_tower.position = build_pos
		get_node("Towers").add_child(drag_tower, true)
		drag_tower.emit_signal("build_complete")
	else:
		print("Can't build tower %s at %s" % [tower_type, build_pos])

func cancel_build_mode():
	build_mode = false
	print("cancel_build_mode")
	var tower_preview = $Canvas/HUD/TowerPreview
	if not tower_preview.is_queued_for_deletion(): 
		tower_preview.free()


func _on_MobSpawner_spawned(mob_name):
	var mob_scene = mob_scene_map[mob_name]
	var mob: Mob = mob_scene.instance()
	
	$MobPath1.add_child(mob)


func _on_HUD_start_wave(wave_index):
	$MobSpawner.start(wave_index)


func _on_HUD_stop_wave():
	$MobSpawner.stop()


func _on_MobSpawner_progress_changed(progress_string):
	$Canvas/HUD/VBoxContainer/WaveProgressLabel.text = progress_string


func _on_MobExit_body_entered(body):
	var body_owner: Node = body.get_owner()
	
	if body_owner is Mob:
		update_mob_exit_count(mobs_exit_count + 1)
		
		var game_over = mobs_exit_count >= mobs_game_over_count
		
		if game_over && !ignore_game_over:
			do_game_over()


# Updates variable and changes value in label
func update_mob_exit_count(new_value):
	mobs_exit_count = new_value
	
	var mob_count_right_text = "%d/%d" % \
	[mobs_exit_count, mobs_game_over_count]
		
	$Canvas/HUD/VBoxContainer/HBoxContainer2/MobCountRight.text = \
	mob_count_right_text


func do_game_over():
	$Canvas/HUD/GameOverLabel.visible = true

func _on_wave_end(wave_index: int):
	GoldManager.add_gold()
	KnowledgeTomesManager.add_knowledge_tomes()
	


func _on_MobSpawner_wave_ended(wave_index):
	pass # Replace with function body.
