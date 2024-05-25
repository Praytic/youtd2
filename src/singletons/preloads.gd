extends Node


# Stores preloaded resources, such as scenes and textures.
# Need to preload scenes here instead of directly in scripts
# to prevent cyclic references. Note that not all of these
# scenes cause cyclic references.


const title_screen_scene: PackedScene = preload("res://src/title_screen/title_screen.tscn")
const game_scene_scene: PackedScene = preload("res://src/game_scene/game_scene.tscn")
const item_button_scene: PackedScene = preload("res://src/hud/buttons/item_button.tscn")
const tower_button_scene: PackedScene = preload("res://src/hud/buttons/tower_button.tscn")
const floating_text_scene: PackedScene = preload("res://src/hud/floating_text.tscn")
const explosion_scene: PackedScene = preload("res://src/effects/explosion.tscn")
const projectile_scene: PackedScene = preload("res://src/projectiles/projectile.tscn")
const aura_scene: PackedScene = preload("res://src/buffs/aura.tscn")
const buff_range_area_scene: PackedScene = preload("res://src/buffs/buff_range_area.tscn")
const corpse_scene: PackedScene = preload("res://src/creeps/creep_corpse.tscn")
const blood_pool_scene: PackedScene = preload("res://src/creeps/creep_blood_pool.tscn")
const flying_item_scene: PackedScene = preload("res://src/hud/flying_item.tscn")
const autocast_button_scene: PackedScene = preload("res://src/hud/buttons/autocast_button.tscn")
const autocast_scene: PackedScene = preload("res://src/towers/autocast.tscn")
const placeholder_effect_scene: PackedScene = preload("res://src/effects/generic_magic.tscn")
const empty_slot_button_scene: PackedScene = preload("res://src/hud/buttons/empty_unit_button.tscn")
const range_indicator_scene: PackedScene = preload("res://src/towers/range_indicator.tscn")
const outline_shader: Material = preload("res://resources/shaders/glowing_outline.material")
const player_scene: PackedScene = preload("res://src/player/player.tscn")
const team_scene: PackedScene = preload("res://src/player/team.tscn")
const tower_preview_scene: PackedScene = preload("res://src/towers/tower_preview.tscn")
const tower_scene: PackedScene = preload("res://src/towers/tower.tscn")
const buff_display_scene: PackedScene = preload("res://src/hud/unit_menu/buff_display.tscn")
const fallback_buff_icon: Texture = preload("res://resources/icons/generic_icons/egg.tres")
const builder_button_scene: PackedScene = preload("res://src/hud/buttons/builder_button.tscn")
const ability_button_scene: PackedScene = preload("res://src/hud/buttons/ability_button.tscn")
const inventory_slot_button_scene: PackedScene = preload("res://src/hud/buttons/inventory_slot_button.tscn")
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
	"OrcChampion": preload("res://src/creeps/instances/orc/orc_champion_creep.tscn"),
	"OrcAir": preload("res://src/creeps/instances/orc/orc_air_creep.tscn"),
	"OrcBoss": preload("res://src/creeps/instances/orc/orc_boss_creep.tscn"),
	"OrcMass": preload("res://src/creeps/instances/orc/orc_mass_creep.tscn"),
	"OrcNormal": preload("res://src/creeps/instances/orc/orc_normal_creep.tscn"),
	
	"ChallengeBoss": preload("res://src/creeps/instances/challenge/challenge_boss_creep.tscn"),
	"ChallengeMass": preload("res://src/creeps/instances/challenge/challenge_mass_creep.tscn"),
}
