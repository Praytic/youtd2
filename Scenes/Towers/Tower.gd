extends Node2D

class_name Tower

signal build_complete
signal build_init

var aoe: AreaOfEffect
onready var _properties = Properties.towers[_internal_name]
onready var attack_range: float = properties["attack_range"]
onready var attack_cd: float = properties["attack_cd"]
onready var id: float = properties["id"]
onready var name: float = properties["name"]
onready var family_id: float = properties["family_id"]
onready var author: float = properties["author"]
onready var rarity: float = properties["rarity"]
onready var attack_cd: float = properties["attack_cd"]
onready var attack_cd: float = properties["attack_cd"]
var _internal_name = get_script().resource_path.get_file().get_basename()

export(int) var size = 32

func _ready():
	aoe = AreaOfEffect.new(attack_range)
	aoe.position = Vector2(size, size) / 2
	connect("build_complete", self, "_on_build_complete")
	connect("build_init", self, "_on_build_init")
	add_child(aoe)
	aoe.hide()
	
func _on_build_complete():
	print("Build complete")
	aoe.hide()

func _on_build_init():
	print("Build init")
	aoe.show()
