extends Control


signal item_dropped(item_id)


var random: RandomNumberGenerator = RandomNumberGenerator.new()
var items: Array = []

onready var mob_ysort: Node2D = get_node(@"%Map").get_node(@"MobYSort")


#########################
### Code starts here  ###
#########################

func _ready():
	random.randomize()
	for item_id in Properties.get_item_properties().keys():
		items.append(Item.new())


func _on_Mob_death(event):
	# TODO: Implement proper item drop chance caclculation
	if random.randf() > .5:
		var item_idx = random.randi_range(0, items.size() - 1)
		var item = items[item_idx]
		
		var item_scene
		match item.get_rarity():
			Constants.Rarity.COMMON: 
				item_scene = load("res://Scenes/Items/CommonItem.tscn")
			Constants.Rarity.UNCOMMON: 
				item_scene = load("res://Scenes/Items/UncommonItem.tscn")
			Constants.Rarity.RARE: 
				item_scene = load("res://Scenes/Items/RareItem.tscn")
			Constants.Rarity.UNIQUE: 
				item_scene = load("res://Scenes/Items/UniqueItem.tscn")
		var item_instance = item_scene.instance()
		item_instance.position = event.get_target().position
		item_instance.set_script(item.get_script())
		mob_ysort.add_child(item_instance, true)
		emit_signal("item_dropped", item.get_id())
