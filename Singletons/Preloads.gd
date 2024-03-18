extends Node


# Stores preloaded resources, such as scenes and textures.
# Need to preload scenes here instead of directly in scripts
# to prevent cyclic references. Note that not all of these
# scenes cause cyclic references.


const item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")
const tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")
const floating_text_scene: PackedScene = preload("res://Scenes/HUD/FloatingText.tscn")
const explosion_scene: PackedScene = preload("res://Scenes/Effects/Explosion.tscn")
const projectile_scene: PackedScene = preload("res://Scenes/Unit/Projectile.tscn")
const aura_scene: PackedScene = preload("res://Scenes/Buffs/Aura.tscn")
const buff_range_area_scene: PackedScene = preload("res://Scenes/Buffs/BuffRangeArea.tscn")
const corpse_scene: PackedScene = preload("res://Scenes/Creeps/CreepCorpse.tscn")
const blood_pool_scene: PackedScene = preload("res://Scenes/Creeps/CreepBloodPool.tscn")
const flying_item_scene: PackedScene = preload("res://Scenes/HUD/FlyingItem.tscn")
const autocast_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AutocastButton.tscn")
const autocast_scene: PackedScene = preload("res://Scenes/Towers/Autocast.tscn")
const placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
const tower_actions_scene: PackedScene = preload("res://Scenes/HUD/TowerActions.tscn")
const empty_slot_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/EmptyUnitButton.tscn")
const range_indicator_scene: PackedScene = preload("res://Scenes/Towers/RangeIndicator.tscn")
const button_with_rich_tooltip_scene: PackedScene = preload("res://Scenes/HUD/ButtonWithRichTooltip.tscn")
const outline_shader: Material = preload("res://Resources/Shaders/GlowingOutline.material")
const special_container: PackedScene = preload("res://Scenes/HUD/UnitMenu/SpecialContainer.tscn")
const player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
const element_icons: Dictionary = {
	Element.enm.ICE: preload("res://Resources/Textures/UI/Icons/ice_icon.tres"),
	Element.enm.NATURE: preload("res://Resources/Textures/UI/Icons/nature_icon.tres"),
	Element.enm.ASTRAL: preload("res://Resources/Textures/UI/Icons/astral_icon.tres"),
	Element.enm.DARKNESS: preload("res://Resources/Textures/UI/Icons/darkness_icon.tres"),
	Element.enm.FIRE: preload("res://Resources/Textures/UI/Icons/fire_icon.tres"),
	Element.enm.IRON: preload("res://Resources/Textures/UI/Icons/iron_icon.tres"),
	Element.enm.STORM: preload("res://Resources/Textures/UI/Icons/storm_icon.tres"),
}
