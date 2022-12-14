extends Node2D

class_name Tower

signal build_complete

var building_in_progress: bool = false

export(int, 32, 64) var size = 32

var aoe: AreaOfEffect
var _internal_name = get_script().resource_path.get_file().get_basename() setget _private_set, _private_get

onready var _properties = Properties.towers[_internal_name] setget _private_set, _private_get
onready var attack_type: String = _properties["attack_type"]
onready var attack_range: float = _properties["attack_range"]
onready var attack_cd: float = _properties["attack_cd"]
onready var id: int = _properties["id"]
onready var ingame_name: String = _properties["name"]
onready var family_id: int = _properties["family_id"]
onready var author: String = _properties["author"]
onready var rarity: String = _properties["rarity"]
onready var element: String = _properties["element"]
onready var damage_l: float = _properties["damage_l"]
onready var damage_r: float = _properties["damage_r"]
onready var cost: float = _properties["cost"]
onready var description: String = _properties["description"]

func _ready():
	aoe = AreaOfEffect.new(attack_range)
	aoe.position = Vector2(size, size) / 2
	connect("build_complete", self, "_on_build_complete")
	add_child(aoe)
	aoe.hide()
	
func _on_build_complete():
	print("Build complete [%s]" % _internal_name)
	aoe.hide()
	building_in_progress = false

func build_init():
	print("Build init [%s]" % _internal_name)
	aoe.show()
	building_in_progress = true

func _private_set(val = null):
	pass
	
func _private_get():
	pass
