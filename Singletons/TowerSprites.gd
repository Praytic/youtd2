extends Node


# Stores loaded tower sprites. Can either load all sprites
# on game startup or load sprites dynamically when they
# become needed. Behavior depends on game config.

const TOWER_SPRITES_DIR: String = "res://Scenes/Towers/TowerSprites"


var _sprite_scene_map: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	var preload_towers: bool = Config.preload_all_towers_on_startup()

	if !preload_towers:
		return

	print_verbose("Start loading tower sprites.")

	var tower_id_list: Array = TowerProperties.get_tower_id_list()

	for tower_id in tower_id_list:
		_load_tower_sprite_scene(tower_id)

	print_verbose("Finished loading tower sprites.")


#########################
###       Public      ###
#########################

func get_sprite(tower_id: int) -> Sprite2D:
	if !_sprite_scene_map.has(tower_id):
		_load_tower_sprite_scene(tower_id)

	var sprite_scene: PackedScene = _sprite_scene_map[tower_id]
	var sprite: Sprite2D = sprite_scene.instantiate()

	return sprite


#########################
###      Private      ###
#########################

# Scene filename = [name of first tier tower in family] +
# tier.
# Examples:
# "Tiny Shrub" -> "TinyShrub1.tscn"
# "Greater Shrub" -> "TinyShrub3.tscn"
func _load_tower_sprite_scene(tower_id: int):
	var family_name: String = TowerProperties.get_family_name(tower_id)
	var tier: int = TowerProperties.get_tier(tower_id)
	var sprite_path: String = "%s/%s%s.tscn" % [TOWER_SPRITES_DIR, family_name, str(tier)]
	
	var sprite_exists: bool = ResourceLoader.exists(sprite_path)
	if !sprite_exists:
		push_error("No sprite scene found for tower id:", tower_id, ". Tried at path:", sprite_path)

		return

	var sprite_scene: PackedScene = load(sprite_path)
	_sprite_scene_map[tower_id] = sprite_scene

	var tower_name: String = TowerProperties.get_display_name(tower_id)
	print_verbose("Loaded tower [%s] with ID [%s]" % [tower_name, tower_id])
