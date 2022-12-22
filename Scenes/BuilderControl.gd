extends Control

onready var map_parent: Node2D = get_tree().current_scene.get_node("DefaultMap")
onready var ground_map: TileMap = get_tree().current_scene.get_node("DefaultMap").get_node("Floor")
onready var towers: Node2D = get_tree().current_scene.get_node("Towers")


var build_mode: bool
var tower_scene: PackedScene = preload("res://Scenes/Towers/Tower.tscn")
var tower_preview: TowerPreview = null
var tower_type: String = ""

func _ready():
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "on_build_button_pressed", [i.get_name()])


func _unhandled_input(event):
	if build_mode:
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
		elif event.is_action_released("ui_accept"):
			verify_and_build()
			cancel_build_mode()


func on_build_button_pressed(tower_type_arg: String):
	if build_mode:
		cancel_build_mode()
	build_mode = true

	tower_type = tower_type_arg

	tower_preview = TowerPreview.new(tower_type)
	var game_scene = get_tree().get_root().get_node("GameScene")
	game_scene.add_child(tower_preview)


func verify_and_build():
	var world_pos = ground_map.get_local_mouse_position()
	var map_pos = ground_map.world_to_map(world_pos)
	var can_build = Utils.map_pos_is_free(map_parent, map_pos)

	if build_mode and can_build:
		var buld_pos = ground_map.map_to_world(map_pos)

		var new_tower = tower_scene.instance()
		new_tower.init_internal_name(tower_type)
		new_tower.position = buld_pos + Vector2(32, 32)
		towers.add_child(new_tower, true)

		tower_preview.queue_free()


func cancel_build_mode():
	build_mode = false

	tower_preview.queue_free()
