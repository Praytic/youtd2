extends Node


# Creates icons for towers and creeps.


const ICON_SIZE = 128
const TIER_ICON_SIZE = 64

const _creep_icons: Texture2D = preload("res://Assets/Mobs/creep_icons_atlas.png")
const _tier_icons_m: Texture2D = preload("res://Assets/Towers/tier_icons_m.png")
const _tower_icons_m: Texture2D = preload("res://Assets/Towers/tower_icons_m.png")
const _placeholder_tower_icon: Texture2D = preload("res://Resources/UI/PlaceholderTowerIcon.tres")


#########################
###       Public      ###
#########################

func get_tower_icon(tower_id: int) -> Texture2D:
	var icon_atlas_num: int = TowerProperties.get_icon_atlas_num(tower_id)

	var tower_has_no_icon: bool = icon_atlas_num == -1
	if tower_has_no_icon:
		return _placeholder_tower_icon
	
	var tower_icon: AtlasTexture = AtlasTexture.new()
	tower_icon.set_atlas(_tower_icons_m)
	
	var region: Rect2 = Rect2(TowerProperties.get_element(tower_id) * ICON_SIZE, icon_atlas_num * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	tower_icon.set_region(region)

	return tower_icon


func get_tower_tier_icon(tower_id: int) -> Texture2D:
	var tower_rarity: Rarity.enm = TowerProperties.get_rarity(tower_id)
	var tower_tier: int = TowerProperties.get_tier(tower_id) - 1

	var icon: AtlasTexture = AtlasTexture.new()
	icon.set_atlas(_tier_icons_m)

	var region: Rect2 = Rect2(tower_tier * TIER_ICON_SIZE, tower_rarity * TIER_ICON_SIZE, TIER_ICON_SIZE, TIER_ICON_SIZE)
	icon.set_region(region)

	return icon


func get_creep_icon(creep: Creep) -> Texture2D:
	var x: int = creep.get_size()
	var y: int = creep.get_category()
	
	assert(x != -1 && y != -1, "Unknown icon for creep [%s]" % creep)

	var icon: AtlasTexture = AtlasTexture.new()
	icon.set_atlas(_creep_icons)
	
	var region: Rect2 = Rect2(x * ICON_SIZE, y * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	icon.set_region(region)

	return icon
