extends Node

# Singleton that manages building towers

signal tower_built(tower_id)


enum BuildState {
	NONE,
	BUILDING,
}


var _build_state: BuildState = BuildState.NONE
var _tower_preview: TowerPreview = null
var _tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
var _occupied_position_map: Dictionary = {}


@onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
@onready var _landscape = _game_scene.get_node("%Map")


func _unhandled_input(event):
	if !in_progress():
		return

	var cancelled: bool = event.is_action_released("ui_cancel")
	
	if cancelled:
		cancel()

	var left_click: bool = event.is_action_released("left_click")
	
	if left_click:
		_try_to_build()


func in_progress() -> bool:
	return _build_state == BuildState.BUILDING


func start(tower_id: int):
	cancel()
	ItemMovement.cancel()
	SelectUnit.set_enabled(false)

	_build_state = BuildState.BUILDING

	_tower_preview = _tower_preview_scene.instantiate()
	_tower_preview.tower_id = tower_id
	_game_scene.add_child(_tower_preview)


func cancel():
	if !in_progress():
		return

	SelectUnit.set_enabled(true)

	_build_state = BuildState.NONE

	_tower_preview.queue_free()


func position_is_occupied(position: Vector2) -> bool:
	var occupied: bool = _occupied_position_map.has(position)

	return occupied


func tower_was_sold(position: Vector2):
	_occupied_position_map.erase(position)


func _try_to_build():
	var can_build: bool = _landscape.can_build_at_mouse_pos()
	
	if can_build:
		var new_tower = TowerManager.get_tower(_tower_preview.tower_id)
		var build_position: Vector2 =_landscape.get_mouse_pos_on_tilemap()
		new_tower.position = build_position
		_occupied_position_map[build_position] = true
		Utils.add_object_to_world(new_tower)
		tower_built.emit(_tower_preview.tower_id)
		
		cancel()
	else:
		var error: String = "Can't build here."
		Globals.error_message_label.add(error)
