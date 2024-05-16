extends Node


# Stores preloaded resources, such as scenes and textures.
# Need to preload scenes here instead of directly in scripts
# to prevent cyclic references. Note that not all of these
# scenes cause cyclic references.


const title_screen_scene: PackedScene = preload("res://src/TitleScreen/TitleScreen.tscn")
const game_scene_scene: PackedScene = preload("res://src/GameScene/GameScene.tscn")
const item_button_scene: PackedScene = preload("res://src/HUD/Buttons/ItemButton.tscn")
const tower_button_scene: PackedScene = preload("res://src/HUD/Buttons/TowerButton.tscn")
const floating_text_scene: PackedScene = preload("res://src/HUD/FloatingText.tscn")
const explosion_scene: PackedScene = preload("res://src/Effects/Explosion.tscn")
const projectile_scene: PackedScene = preload("res://src/Projectiles/Projectile.tscn")
const aura_scene: PackedScene = preload("res://src/buffs/Aura.tscn")
const buff_range_area_scene: PackedScene = preload("res://src/buffs/BuffRangeArea.tscn")
const corpse_scene: PackedScene = preload("res://src/Creeps/CreepCorpse.tscn")
const blood_pool_scene: PackedScene = preload("res://src/Creeps/CreepBloodPool.tscn")
const flying_item_scene: PackedScene = preload("res://src/HUD/FlyingItem.tscn")
const autocast_button_scene: PackedScene = preload("res://src/HUD/Buttons/AutocastButton.tscn")
const autocast_scene: PackedScene = preload("res://src/Towers/Autocast.tscn")
const placeholder_effect_scene: PackedScene = preload("res://src/Effects/GenericMagic.tscn")
const empty_slot_button_scene: PackedScene = preload("res://src/HUD/Buttons/EmptyUnitButton.tscn")
const range_indicator_scene: PackedScene = preload("res://src/Towers/RangeIndicator.tscn")
const outline_shader: Material = preload("res://resources/shaders/GlowingOutline.material")
const special_container: PackedScene = preload("res://src/HUD/UnitMenu/SpecialContainer.tscn")
const player_scene: PackedScene = preload("res://src/Player/Player.tscn")
const team_scene: PackedScene = preload("res://src/Player/Team.tscn")
const tower_preview_scene: PackedScene = preload("res://src/Towers/TowerPreview.tscn")
const tower_scene: PackedScene = preload("res://src/Towers/Tower.tscn")
const buff_display_scene: PackedScene = preload("res://src/HUD/UnitMenu/BuffDisplay.tscn")
const fallback_buff_icon: Texture = preload("res://resources/icons/generic_icons/egg.tres")
const builder_button_scene: PackedScene = preload("res://src/HUD/Buttons/BuilderButton.tscn")
const ability_button_scene: PackedScene = preload("res://src/HUD/Buttons/AbilityButton.tscn")
const element_icons: Dictionary = {
	Element.enm.ICE: preload("res://resources/icons/elements/ice.tres"),
	Element.enm.NATURE: preload("res://resources/icons/elements/nature.tres"),
	Element.enm.ASTRAL: preload("res://resources/icons/elements/astral.tres"),
	Element.enm.DARKNESS: preload("res://resources/icons/elements/darkness.tres"),
	Element.enm.FIRE: preload("res://resources/icons/elements/fire.tres"),
	Element.enm.IRON: preload("res://resources/icons/elements/iron.tres"),
	Element.enm.STORM: preload("res://resources/icons/elements/storm.tres"),
}


const creep_scenes: Dictionary = {
	"OrcChampion": preload("res://src/Creeps/Instances/Orc/OrcChampionCreep.tscn"),
	"OrcAir": preload("res://src/Creeps/Instances/Orc/OrcAirCreep.tscn"),
	"OrcBoss": preload("res://src/Creeps/Instances/Orc/OrcBossCreep.tscn"),
	"OrcMass": preload("res://src/Creeps/Instances/Orc/OrcMassCreep.tscn"),
	"OrcNormal": preload("res://src/Creeps/Instances/Orc/OrcNormalCreep.tscn"),
	
	"ChallengeBoss": preload("res://src/Creeps/Instances/Challenge/ChallengeBossCreep.tscn"),
	"ChallengeMass": preload("res://src/Creeps/Instances/Challenge/ChallengeMassCreep.tscn"),
}
