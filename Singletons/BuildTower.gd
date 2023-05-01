extends Node

# Singleton that manages building towers

signal tower_built(tower_id)


@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
@onready var _landscape = _game_scene.get_node("%Map")


var _build_mode: bool = false
var _tower_preview: TowerPreview = null
var _tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
var _occupied_position_map: Dictionary = {}


func _unhandled_input(event):
	if _build_mode:
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
		elif event.is_action_released("ui_accept"):
			var build_success: bool = verify_and_build()

			if build_success:
				cancel_build_mode()


func start_building_tower(tower_id: int):
	if _build_mode:
		cancel_build_mode()
	_build_mode = true

	_tower_preview = _tower_preview_scene.instantiate()
	_tower_preview.tower_id = tower_id
	_game_scene.add_child(_tower_preview)


func verify_and_build() -> bool:
	if _build_mode and _landscape.can_build_at_mouse_pos():
		var new_tower = TowerManager.get_tower(_tower_preview.tower_id)
		var build_position: Vector2 =_landscape.get_mouse_pos_on_tilemap()
		new_tower.position = build_position
		_occupied_position_map[build_position] = true
		Utils.add_object_to_world(new_tower)
		tower_built.emit(_tower_preview.tower_id)
		_tower_preview.queue_free()

		return true
	else:
		var error: String = "Can't build here."
		Globals.error_message_label.add(error)

		return false


func cancel_build_mode():
	_build_mode = false

	_tower_preview.queue_free()


func build_tower_in_progress() -> bool:
	return _build_mode == true


func position_is_occupied(position: Vector2) -> bool:
	var occupied: bool = _occupied_position_map.has(position)

	return occupied


func tower_was_sold(position: Vector2):
	_occupied_position_map.erase(position)
