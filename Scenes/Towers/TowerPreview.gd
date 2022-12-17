extends Node2D


class_name TowerPreview


onready var map_parent: Node2D = get_tree().current_scene.get_node("DefaultMap")
onready var ground_map: Node2D = get_tree().current_scene.get_node("DefaultMap").get_node("Ground")


var tile_size = 64

const opaque_red := Color("adff4545")
const opaque_green := Color("ad54ff3c")


func _init(tower_type):
	var drag_tower = load("res://Scenes/Towers/Tower.tscn").instance()
	drag_tower.init_internal_name("GunT1")
	drag_tower.set_name("DragTower")

	add_child(drag_tower)
	set_meta("type", tower_type)


func _ready():
	$DragTower.build_init()


func _physics_process(_delta):
	$DragTower.modulate = get_current_color()
	position = get_current_pos()


func get_current_color() -> Color:
	var world_pos = ground_map.get_local_mouse_position()
	var map_pos = ground_map.world_to_map(world_pos)

	if Utils.map_pos_is_free(map_parent, map_pos):
		return opaque_green
	else:
		return opaque_red


func get_current_pos() -> Vector2:
	var world_pos = ground_map.get_local_mouse_position()
	var map_pos = ground_map.world_to_map(world_pos)
	var clamped_world_pos = ground_map.map_to_world(map_pos)

#	Add half-tile because tower sprite position is at center
	var out: Vector2 = clamped_world_pos + Vector2(tile_size / 2, tile_size / 2)
	
	return out
