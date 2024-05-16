class_name TestItemsTool extends Node


# Tests items by creating all items.


static func run(gamescene: Node, player: Player):
	var scene_tree: SceneTree = gamescene.get_tree()
	var item_id_list: Array = ItemProperties.get_item_id_list()

	var i: int = 0

	var tower: Tower = Tower.make(1, player)
	tower.set_position_wc3_2d(Vector2(123, 123))
	Utils.add_object_to_world(tower)

	for item_id in item_id_list:
		var item_name: String = ItemProperties.get_display_name(item_id)
		print("(%d/%d) Testing item %d %s" % [i + 1, item_id_list.size(), item_id, item_name])

		var item: Item = Item.make(item_id, player)
		Item.make_item_drop(item, Vector3.ZERO)
		item.pickup(tower)
		await scene_tree.create_timer(0.01).timeout
		item.drop()
		await scene_tree.create_timer(0.01).timeout
		item.queue_free()
		await scene_tree.create_timer(0.01).timeout

		i += 1
