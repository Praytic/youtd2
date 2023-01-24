extends Building


class_name Tower


signal upgraded


export(int) var id
export(int) var next_tier_id

var attack_type: String
var ingame_name: String
var author: String
var rarity: String
var element: String
var damage_l: float
var damage_r: float
var cost: float
var description: String


var projectile_spell_scene: PackedScene = preload("res://Scenes/Towers/ProjectileSpell.tscn")
var proximity_spell_scene: PackedScene = preload("res://Scenes/Towers/ProximitySpell.tscn")
var aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")

var spell_node_list: Array = []


func _ready():
	add_child(aoe_scene.instance(), true)
	
	var properties = TowerManager.tower_props[id]
	attack_type = properties["attack_type"]
	ingame_name = properties["name"]
	author = properties["author"]
	rarity = properties["rarity"]
	element = properties["element"]
	cost = properties["cost"]
	description = properties["description"]

	$AuraContainer.connect("applied", self, "_on_AuraContainer_applied")

	var cast_range: float = 100.0

	var spell_list: Array = properties["spell_list"]

	for spell_info in spell_list:
		var spell_type: String = spell_info["type"]
		var spell_node: Node = make_spell(spell_type)
		spell_node.init(spell_info)
		add_child(spell_node)
		spell_node_list.append(spell_node)

#		HACK: to set some radius for areaofeffect indicator.
#		Don't know what to do for multiple aura's. Draw
#		multiple indicators for each aura? Draw only the
#		largest one? Draw only the range for projectile
#		spell?
		cast_range = spell_info["cast_range"]

	$AreaOfEffect.set_radius(cast_range)
	$AreaOfEffect.hide()
	

func make_spell(type: String) -> Node:
	match type:
		"projectile": return projectile_spell_scene.instance()
		"proximity": return proximity_spell_scene.instance()
		_:
			print_debug("Unknown spell type: %s. Defaulting to projectile." % type)
			return projectile_spell_scene.instance()


func build_init():
	.build_init()
	$AreaOfEffect.show()

	# NOTE: removing spell nodes so that tower preview doesn't cast, a bit hacky, can be improved with refactoring
	for spell_node in spell_node_list:
		spell_node.queue_free()


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


func add_aura_list(aura_info_list: Array):
	$AuraContainer.add_aura_list(aura_info_list)


func _on_AuraContainer_applied(aura: Aura):
	for spell_node in spell_node_list:
		spell_node.apply_aura(aura)
