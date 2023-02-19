extends Control


signal item_dropped(item_id)


var random: RandomNumberGenerator = RandomNumberGenerator.new()

onready var mob_ysort: Node2D = get_node(@"%Map").get_node(@"MobYSort")


#########################
### Code starts here  ###
#########################

func _ready():
	random.randomize()


func _on_Mob_death(event):
	# TODO: Implement proper item drop chance caclculation
	if random.randf() > .5:
		var scene_name_list: Array = Properties.get_item_scene_name_list()
		var item_idx = random.randi_range(0, scene_name_list.size() - 1)
		var item_scene_name = scene_name_list[item_idx]
		var item_scene_path: String = "res://Scenes/Items/Instances/%s.tscn" % [item_scene_name]
		var item_scene = load(item_scene_path)
		var item_instance = item_scene.instance()
		item_instance.position = event.get_target().position
		mob_ysort.add_child(item_instance, true)
		emit_signal("item_dropped", item_instance.get_id())
