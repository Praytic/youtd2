class_name ActionDropItem


static func make(item_uid_arg: int, position_arg: Vector2, src_item_container_uid_arg: int) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.DROP_ITEM,
		Action.Field.POSITION: position_arg,
		Action.Field.UID: item_uid_arg,
		Action.Field.SRC_ITEM_CONTAINER_UID: src_item_container_uid_arg,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var position_canvas: Vector2 = action[Action.Field.POSITION]
	var item_uid: int = action[Action.Field.UID]
	var src_item_container_uid: int = action[Action.Field.SRC_ITEM_CONTAINER_UID]

	var item: Item = GroupManager.get_by_uid("items", item_uid)
	var src_item_container: ItemContainer = GroupManager.get_by_uid("item_containers", src_item_container_uid)

	var verify_ok: bool = ActionDropItem.verify(player, item, src_item_container)
	if !verify_ok:
		return

	src_item_container.remove_item(item)

	var position_wc3_2d: Vector2 = VectorUtils.canvas_to_wc3_2d(position_canvas)
	var position_wc3: Vector3 = Vector3(position_wc3_2d.x, position_wc3_2d.y, 0)
	var item_drop: ItemDrop = ItemDrop.make(item, position_wc3)
	Utils.add_object_to_world(item_drop)
	item.fly_to_stash(0.0)


static func verify(player: Player, item: Item, src_container: ItemContainer) -> bool:
	if item == null || src_container == null:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_DROP_ITEM"))
		
		return false

	var item_exists_in_src_container: bool = src_container.has(item)
	if !item_exists_in_src_container:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_FAIL_DROP_ITEM"))
		
		return false

	var player_match: bool = item.get_player() == player && src_container.get_player() == player
	if !player_match:
		Utils.add_ui_error(player, Utils.tr("MESSAGE_DONT_OWN_ITEM"))

		return false

	return true
