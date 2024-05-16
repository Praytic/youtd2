extends Node


# Stores preloaded resources, such as scenes and textures.
# Need to preload scenes here instead of directly in scripts
# to prevent cyclic references. Note that not all of these
# scenes cause cyclic references.


const title_screen_scene: PackedScene = preload("res://Scenes/TitleScreen/TitleScreen.tscn")
const game_scene_scene: PackedScene = preload("res://Scenes/GameScene/GameScene.tscn")
const item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")
const tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")
const floating_text_scene: PackedScene = preload("res://Scenes/HUD/FloatingText.tscn")
const explosion_scene: PackedScene = preload("res://Scenes/Effects/Explosion.tscn")
const projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Projectile.tscn")
const aura_scene: PackedScene = preload("res://Scenes/buffs/Aura.tscn")
const buff_range_area_scene: PackedScene = preload("res://Scenes/buffs/BuffRangeArea.tscn")
const corpse_scene: PackedScene = preload("res://Scenes/Creeps/CreepCorpse.tscn")
const blood_pool_scene: PackedScene = preload("res://Scenes/Creeps/CreepBloodPool.tscn")
const flying_item_scene: PackedScene = preload("res://Scenes/HUD/FlyingItem.tscn")
const autocast_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AutocastButton.tscn")
const autocast_scene: PackedScene = preload("res://Scenes/Towers/Autocast.tscn")
const placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
const empty_slot_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/EmptyUnitButton.tscn")
const range_indicator_scene: PackedScene = preload("res://Scenes/Towers/RangeIndicator.tscn")
const outline_shader: Material = preload("res://Resources/Shaders/GlowingOutline.material")
const special_container: PackedScene = preload("res://Scenes/HUD/UnitMenu/SpecialContainer.tscn")
const player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
const team_scene: PackedScene = preload("res://Scenes/Player/Team.tscn")
const tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
const tower_scene: PackedScene = preload("res://Scenes/Towers/Tower.tscn")
const buff_display_scene: PackedScene = preload("res://Scenes/HUD/UnitMenu/BuffDisplay.tscn")
const fallback_buff_icon: Texture = preload("res://Resources/Icons/GenericIcons/egg.tres")
const builder_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/BuilderButton.tscn")
const ability_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AbilityButton.tscn")
const element_icons: Dictionary = {
	Element.enm.ICE: preload("res://Resources/Icons/elements/ice.tres"),
	Element.enm.NATURE: preload("res://Resources/Icons/elements/nature.tres"),
	Element.enm.ASTRAL: preload("res://Resources/Icons/elements/astral.tres"),
	Element.enm.DARKNESS: preload("res://Resources/Icons/elements/darkness.tres"),
	Element.enm.FIRE: preload("res://Resources/Icons/elements/fire.tres"),
	Element.enm.IRON: preload("res://Resources/Icons/elements/iron.tres"),
	Element.enm.STORM: preload("res://Resources/Icons/elements/storm.tres"),
}


const creep_scenes: Dictionary = {
	"OrcChampion": preload("res://Scenes/Creeps/Instances/Orc/OrcChampionCreep.tscn"),
	"OrcAir": preload("res://Scenes/Creeps/Instances/Orc/OrcAirCreep.tscn"),
	"OrcBoss": preload("res://Scenes/Creeps/Instances/Orc/OrcBossCreep.tscn"),
	"OrcMass": preload("res://Scenes/Creeps/Instances/Orc/OrcMassCreep.tscn"),
	"OrcNormal": preload("res://Scenes/Creeps/Instances/Orc/OrcNormalCreep.tscn"),
	
	"ChallengeBoss": preload("res://Scenes/Creeps/Instances/Challenge/ChallengeBossCreep.tscn"),
	"ChallengeMass": preload("res://Scenes/Creeps/Instances/Challenge/ChallengeMassCreep.tscn"),
}
