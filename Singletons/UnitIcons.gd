extends Node


# Creates icons for towers and creeps.


const ICON_SIZE = 128
const TIER_ICON_SIZE = 64

const _creep_icons: Texture2D = preload("res://Assets/Mobs/creep_icons_atlas.png")
const _tier_icons_m: Texture2D = preload("res://Assets/Towers/tier_icons_m.png")
const _tower_icons_m: Texture2D = preload("res://Assets/Towers/tower_icons_m.png")
const _placeholder_tower_icon: Texture2D = preload("res://Resources/UI/PlaceholderTowerIcon.tres")
const CREEP_ICON_DIR: String = "res://Resources/Textures/CreepIcons"


#########################
###     Built-in      ###
#########################

func _ready():
#	Check icon paths
	var creep_category_list: Array[CreepCategory.enm] = CreepCategory.get_list()
	var creep_size_list: Array[CreepSize.enm] = CreepSize.get_list()

	for creep_category in creep_category_list:
		for creep_size in creep_size_list:
			var size_is_challenge: bool = CreepSize.is_challenge(creep_size)
			var category_is_challenge: bool = creep_category == CreepCategory.enm.CHALLENGE
			var invalid_challenge_combo: bool = (size_is_challenge && !category_is_challenge) || (!size_is_challenge && category_is_challenge) 
	
			if invalid_challenge_combo:
				continue

			var icon_path: String = UnitIcons._get_creep_icon_path(creep_category, creep_size)
			var icon_path_is_valid: bool = ResourceLoader.exists(icon_path)

			if !icon_path_is_valid:
				push_error("Invalid creep icon path: %s" % icon_path)


#########################
###       Public      ###
#########################

func get_tower_tier_icon(tower_id: int) -> Texture2D:
	var tower_rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
	var tower_tier: int = TowerProperties.get_tier(tower_id) - 1

	var icon: AtlasTexture = AtlasTexture.new()
	icon.set_atlas(_tier_icons_m)

	var region: Rect2 = Rect2(tower_tier * TIER_ICON_SIZE, tower_rarity * TIER_ICON_SIZE, TIER_ICON_SIZE, TIER_ICON_SIZE)
	icon.set_region(region)

	return icon


func get_creep_icon(creep: Creep) -> Texture2D:
	var creep_size: CreepSize.enm = creep.get_size()
	var creep_category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
	var icon_path: String = _get_creep_icon_path(creep_category, creep_size)
	var icon_path_exists: bool = ResourceLoader.exists(icon_path)

	if !icon_path_exists:
		push_error("Icon path doesn't exist")

		return Texture2D.new()

	var icon: Texture2D = load(icon_path)

	return icon


func _get_creep_icon_path(creep_category: CreepCategory.enm, creep_size: CreepSize.enm) -> String:
	var creep_category_string: String = CreepCategory.convert_to_string(creep_category)
	var creep_size_string: String = CreepSize.convert_to_string(creep_size)
	var icon_path: String = "%s/%s_%s.tres" % [CREEP_ICON_DIR, creep_category_string, creep_size_string]
	icon_path = icon_path.replace(" ", "_")

	return icon_path
