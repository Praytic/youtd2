extends Node


const item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")
const tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")
const unit_button_container_scene: PackedScene = preload("res://Scenes/HUD/Buttons/UnitButtonContainer.tscn")
const floating_text_scene: PackedScene = preload("res://Scenes/FloatingText.tscn")
const explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
const projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
const aura_scene: PackedScene = preload("res://Scenes/Buffs/Aura.tscn")
const buff_range_area_scene: PackedScene = preload("res://Scenes/Buffs/BuffRangeArea.tscn")
const corpse_scene: PackedScene = preload("res://Scenes/Creeps/CreepCorpse.tscn")
const flying_item_scene: PackedScene = preload("res://Scenes/HUD/FlyingItem.tscn")
const autocast_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AutocastButton.tscn")
const autocast_scene: PackedScene = preload("res://Scenes/Towers/Autocast.tscn")
const tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
const placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
const placeholder_tower_scene: PackedScene = preload("res://Scenes/Towers/Instances/PlaceholderTower.tscn")
const tower_actions_scene: PackedScene = preload("res://Scenes/HUD/TowerActions.tscn")
const empty_slot_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/EmptySlotButton.tscn")


var wave_count: int
var game_mode: GameMode.enm
var difficulty: Difficulty.enm
var portal_lives: float = 100.0
var game_over: bool = false


func game_mode_is_random() -> bool:
	return Globals.game_mode == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.game_mode == GameMode.enm.TOTALLY_RANDOM
