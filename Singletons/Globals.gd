extends Node


var item_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/ItemButton.tscn")
var tower_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/TowerButton.tscn")
var floating_text_scene: PackedScene = preload("res://Scenes/FloatingText.tscn")
var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var aura_scene: PackedScene = preload("res://Scenes/Buffs/Aura.tscn")
var buff_range_area_scene: PackedScene = preload("res://Scenes/Buffs/BuffRangeArea.tscn")
var corpse_scene: PackedScene = preload("res://Scenes/Creeps/CreepCorpse.tscn")
var flying_item_scene: PackedScene = preload("res://Scenes/HUD/FlyingItem.tscn")
var autocast_button_scene: PackedScene = preload("res://Scenes/HUD/Buttons/AutocastButton.tscn")
var autocast_scene: PackedScene = preload("res://Scenes/Towers/Autocast.tscn")
var tower_preview_scene: PackedScene = preload("res://Scenes/Towers/TowerPreview.tscn")
var placeholder_effect_scene: PackedScene = preload("res://Scenes/Effects/GenericMagic.tscn")
var placeholder_tower_scene: PackedScene = preload("res://Scenes/Towers/Instances/PlaceholderTower.tscn")


var difficulty: Difficulty.enm = Difficulty.enm.BEGINNER
