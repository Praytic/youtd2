extends Node


enum GameState {
	PREGAME,
	TUTORIAL,
	PLAYING,
	PAUSED,
}


const item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")
const tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")
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
const range_indicator_scene: PackedScene = preload("res://Scenes/Towers/RangeIndicator.tscn")
const button_with_rich_tooltip_scene: PackedScene = preload("res://Scenes/HUD/ButtonWithRichTooltip.tscn")


var game_over: bool = false
var _total_damage: float = 0.0
var built_at_least_one_tower: bool = false
var room_code: String
var _game_state: GameState

# NOTE: HACK BELOW
# See GlaiveMaster script for explanation.
var is_inside_periodic_event: bool = false


func add_to_total_damage(amount: float):
	_total_damage += amount


func get_total_damage() -> float:
	return _total_damage


func set_game_state(value: GameState):
	_game_state = value


func get_game_state() -> GameState:
	return _game_state
