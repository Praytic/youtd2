extends Node2D


class_name TowerPreview


onready var map_parent: Node2D = get_tree().current_scene.get_node("DefaultMap").get_node("Floor")
onready var ground_map: TileMap = get_tree().current_scene.get_node("DefaultMap").get_node("Floor").get_node("BuildableArea")


var tile_size = 64

const opaque_red := Color("adff4545")
const opaque_green := Color("ad54ff3c")
var tower: Tower = null


func _init(tower_type):
	tower = load("res://Scenes/Towers/Tower.tscn").instance()
	tower.init_internal_name(tower_type)
	add_child(tower)


func _ready():
	tower.build_init()


func _physics_process(_delta):
	tower.modulate = get_current_color()
	position = get_current_pos()
	update()


func get_current_color() -> Color:
	var world_pos = ground_map.get_local_mouse_position()
	var map_pos = ground_map.world_to_map(world_pos)

	if Utils.map_pos_is_free(map_parent, ground_map, map_pos):
		return opaque_green
	else:
		return opaque_red

onready var iso_to_cart: Transform2D = Transform2D().scaled(Vector2(1, 0.5)) * Transform2D(PI/4, Vector2())
# Scale a transformation then rotate it (or maybe rotate then scale, not sure how it worked exactly..)
onready var cart_to_iso: Transform2D = iso_to_cart.affine_inverse()
onready var map_to_world: Transform2D = Transform2D().scaled(Vector2(256.0, 256.0))

func get_current_pos() -> Vector2:
	var world_pos = ground_map.get_local_mouse_position()
	var map_pos = ground_map.world_to_map(world_pos)
	var clamped_world_pos = ground_map.map_to_world(map_pos)

#	Add half-tile because tower sprite position is at center
	var out: Vector2 = clamped_world_pos + Vector2(tile_size / 2, tile_size / 2)
	
	return out
