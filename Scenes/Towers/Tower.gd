extends Building


class_name Tower


signal upgraded


export(int) var id
export(int) var next_tier_id

var attack_type: String
var attack_range: float
var attack_cd: float
var attack_style_string: String
var ingame_name: String
var author: String
var rarity: String
var element: String
var damage_l: float
var damage_r: float
var cost: float
var description: String


var attack_shoot_scene: PackedScene = preload("res://Scenes/Towers/AttackShoot.tscn")
var attack_aoe_scene: PackedScene = preload("res://Scenes/Towers/AttackAoe.tscn")
var aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")

var attack_node: Node = null


func _ready():
	add_child(aoe_scene.instance(), true)
	
	var properties = TowerManager.tower_props[id]
	attack_type = properties["attack_type"]
	attack_range = properties["attack_range"]
	attack_cd = properties["attack_cd"]
	attack_style_string = properties["attack_style"]
	ingame_name = properties["name"]
	author = properties["author"]
	rarity = properties["rarity"]
	element = properties["element"]
	damage_l = properties["damage_l"]
	damage_r = properties["damage_r"]
	cost = properties["cost"]
	description = properties["description"]

	$AreaOfEffect.set_radius(attack_range)
	$AreaOfEffect.hide()

	attack_node = make_attack_node(attack_style_string)
	add_child(attack_node)
	attack_node.init(attack_range, attack_cd)
	

func make_attack_node(attack_style: String) -> Node:
	match attack_style:
		"shoot": return attack_shoot_scene.instance()
		"aoe": return attack_aoe_scene.instance()
		_:
			print_debug("Unknown attack style: %s. Defaulting to shoot." % attack_style)
			return attack_shoot_scene.instance()


func build_init():
	.build_init()
	$AreaOfEffect.show()

	# NOTE: removing attack node so that tower preview doesn't shoot, a bit hacky, can be improved with refactoring
	if attack_node != null:
		attack_node.queue_free()


func _select():
	._select()
	print_debug("Tower %s has been selected." % id)


func _unselect():
	._unselect()
	print_debug("Tower %s has been unselected." % id)


func upgrade() -> PackedScene:
	var next_tier_tower = TowerManager.get_tower(next_tier_id)
	emit_signal("upgraded")
	return next_tier_tower
