extends ItemBehavior


var multiboard: MultiboardValues
var copied_item_list: Array[Item] = []


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Imitation[/color]\n"
	text += "On pick up, this item copies effects of other items in tower inventory, except active abilities and other Distorted Idols.\n" \
	+ " \n" \
	+ "The effects are lost when this item is dropped or the carrier is upgraded or transformed.\n" \
	+ " \n" \
	+ "[color=GOLD]Restriction[/color]\n" \
	+ "This item can only be picked up by a tower in a corner with cliffs on two sides."
	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.60, 0.0)

func create_multiboard(size: int):
	multiboard = MultiboardValues.new(size)
	for i in range(size):
		multiboard.set_key(i, "Distorted #%s" % i)

func item_init():
	create_multiboard(1)

func on_pickup():
	var carrier: Tower = item.get_carrier()
	var player: Player = item.get_player()
	
	var carrier_is_on_corner: bool = get_carrier_is_on_corner()

#	NOTE: need delay before dropping item because
#	immediately dropping after adding to inventory
#	causes problems
	if !carrier_is_on_corner:
		player.display_floating_text("Distorted Idol carrier must be on corner!", carrier, Color.PURPLE)

		await Utils.create_timer(0.1, self).timeout
		
		item.drop()
		item.fly_to_stash(0.0)

		return

	var item_list: Array[Item] = carrier.get_items()
	var distorted_idol_id: int = item.get_id()

	for original_item in item_list:
		var copied_item_id: int = original_item.get_id()
		var is_distorted_idol: bool = copied_item_id == distorted_idol_id

		if is_distorted_idol:
			continue

#       NOTE: adding item to tower without adding to
#       inventory. This applies all item effects without
#       occupying a slot in inventory.
# 
#       NOTE: need to use make() instead of create() because
#       ItemDrop is not needed here.
		var copied_item: Item = Item.make(copied_item_id, player)
		copied_item._add_to_tower(carrier)
		copied_item.disable_autocast()
		item.add_child(copied_item)
		copied_item_list.append(copied_item)
	
	create_multiboard(len(copied_item_list))


func on_drop():
	for copied_item in copied_item_list:
		copied_item._remove_from_tower()
		item.remove_child(copied_item)
		copied_item.queue_free()

	copied_item_list.clear()


func on_tower_details() -> MultiboardValues:
	var index: int = 0

	for copied_item in copied_item_list:
		var copied_item_name: String = copied_item.get_display_name()
		multiboard.set_value(index, copied_item_name)
	
		index += 1

	return multiboard


func get_carrier_is_on_corner() -> bool:
	var game_scene: GameScene = get_tree().get_root().get_node("GameScene")
	var build_space: BuildSpace = game_scene.get_build_space()

	var carrier: Tower = item.get_carrier()
	var carrier_pos_canvas: Vector2 = carrier.get_visual_position()
	var carrier_pos_map: Vector2i = build_space._convert_pos_canvas_to_map(carrier_pos_canvas)
	var player: Player = carrier.get_player()
	
	var offset_list: Array[Vector2i] = [
		Vector2i(2, 0),
		Vector2i(-2, 0),
		Vector2i(0, 2),
		Vector2i(0, -2),
	]

	var non_buildable_count: int = 0

	for offset in offset_list:
		var neighbor_pos: Vector2i = carrier_pos_map + offset
		var is_buildable: bool = build_space.buildable_cell_exists_at_pos(player, neighbor_pos)

		if !is_buildable:
			non_buildable_count += 1

	var is_corner: bool = non_buildable_count >= 2

	return is_corner
