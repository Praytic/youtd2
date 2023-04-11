extends Control


signal tower_built(tower_id)


@onready var object_ysort: Node2D = get_node("%Map").get_node("ObjectYSort")
@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
@onready var _landscape = get_node("%Map")
@onready var gold_control = get_tree().current_scene.get_node("%GoldControl")


var build_mode: bool = false
var tower_preview: TowerPreview = null
var _tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")


func _unhandled_input(event):
	if build_mode:
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
		elif event.is_action_released("ui_accept"):
			verify_and_build()
			cancel_build_mode()


func on_build_button_pressed(tower_id: int):
	if build_mode:
		cancel_build_mode()
	build_mode = true

	tower_preview = _tower_preview_scene.instantiate()
	tower_preview.tower_id = tower_id
	_game_scene.add_child(tower_preview)


func verify_and_build():
	if build_mode and _landscape.can_build_at_mouse_pos():
		var new_tower = TowerManager.get_tower(tower_preview.tower_id)
		new_tower.position = _landscape.get_current_buildable_pos()
		object_ysort.add_child(new_tower, true)
		tower_built.emit(tower_preview.tower_id)
		tower_preview.queue_free()


func cancel_build_mode():
	build_mode = false

	tower_preview.queue_free()
