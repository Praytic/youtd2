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
const blood_pool_scene: PackedScene = preload("res://Scenes/Creeps/CreepBloodPool.tscn")
const flying_item_scene: PackedScene = preload("res://Scenes/HUD/FlyingItem.tscn")
const autocast_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AutocastButton.tscn")
const autocast_scene: PackedScene = preload("res://Scenes/Towers/Autocast.tscn")
const tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
const placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
const placeholder_tower_scene: PackedScene = preload("res://Scenes/Towers/Instances/PlaceholderTower.tscn")
const tower_actions_scene: PackedScene = preload("res://Scenes/HUD/TowerActions.tscn")
const empty_slot_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/EmptyUnitButton.tscn")


var wave_count: int
var game_mode: GameMode.enm
var difficulty: Difficulty.enm
var game_over: bool = false
var _total_damage: float = 0.0
var built_at_least_one_tower: bool = false


func game_mode_is_random() -> bool:
	return Globals.game_mode == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.game_mode == GameMode.enm.TOTALLY_RANDOM


func add_to_total_damage(amount: float):
	_total_damage += amount


func get_total_damage() -> float:
	return _total_damage
