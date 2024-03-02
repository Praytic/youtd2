extends Node


enum GameState {
	PREGAME,
	TUTORIAL,
	PLAYING,
	PAUSED,
}


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
const tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
const placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
const placeholder_tower_scene: PackedScene = preload("res://Scenes/Towers/Instances/PlaceholderTower.tscn")
const tower_actions_scene: PackedScene = preload("res://Scenes/HUD/TowerActions.tscn")
const empty_slot_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/EmptyUnitButton.tscn")
const range_indicator_scene: PackedScene = preload("res://Scenes/Towers/RangeIndicator.tscn")
const button_with_rich_tooltip_scene: PackedScene = preload("res://Scenes/HUD/ButtonWithRichTooltip.tscn")
const outline_shader: Material = preload("res://Resources/Shaders/GlowingOutline.material")
const special_container: PackedScene = preload("res://Scenes/HUD/TowerMenu/SpecialContainer.tscn")


var game_over: bool = false
var _total_damage: float = 0.0
var built_at_least_one_tower: bool = false
var room_code: String
var _game_state: GameState
var _builder_instance: Builder
var _builder_range_bonus: float = 0
var _builder_tower_lvl_bonus: int = 0
var _builder_item_slots_bonus: int = 0


func add_to_total_damage(amount: float):
	_total_damage += amount


func get_total_damage() -> float:
	return _total_damage


func set_game_state(value: GameState):
	_game_state = value


func get_game_state() -> GameState:
	return _game_state


func get_builder() -> Builder:
	return _builder_instance


func get_builder_range_bonus() -> float:
	return _builder_range_bonus


func get_builder_tower_lvl_bonus() -> int:
	return _builder_tower_lvl_bonus


func get_builder_item_slots_bonus() -> int:
	return _builder_item_slots_bonus
