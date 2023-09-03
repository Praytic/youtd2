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
var _total_damage: float = 0.0
var _ticks_at_game_start: int = 0


func game_mode_is_random() -> bool:
	return Globals.game_mode == GameMode.enm.RANDOM_WITH_UPGRADES || Globals.game_mode == GameMode.enm.TOTALLY_RANDOM


func reduce_portal_lives(amount: float):
	portal_lives = max(0.0, portal_lives - amount)

	if portal_lives == 0.0 && !game_over:
		Messages.add_normal("[color=RED]The portal has been destroyed! The game is over.[/color]")
		game_over = true
		EventBus.game_over.emit()


func get_lives_string() -> String:
	var lives_string: String = Utils.format_percent(floori(portal_lives) / 100.0, 2)

	return lives_string


func add_to_total_damage(amount: float):
	_total_damage += amount


func get_total_damage() -> float:
	return _total_damage
