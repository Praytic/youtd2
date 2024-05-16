class_name ActionAutofill


# NOTE: autofill action needs to store the item list because
# it is simpler. An alternative approach would be to pass
# recipe and rarity filter, which couples multiplayer peers
# too much to UI state of player who initiated the autofill
# action.


static func make(autofill_uid_list: Array[int]) -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.AUTOFILL,
		Action.Field.UID_LIST: autofill_uid_list,
		})

	return action


static func execute(action: Dictionary, player: Player):
	var autofill_uid_list: Array = action[Action.Field.UID_LIST]

	var autofill_list: Array[Item] = []
	for item_uid in autofill_uid_list:
		var item_node: Node = GroupManager.get_by_uid("items", item_uid)
		var item: Item = item_node as Item

		if item == null:
			Messages.add_error(player, "Failed to autofill.")

			return

		autofill_list.append(item)

	var item_stash: ItemContainer = player.get_item_stash()
	var horadric_stash: ItemContainer = player.get_horadric_stash()

# 	Return current horadric cube contents to item stash
	var horadric_items_initial: Array[Item] = horadric_stash.get_item_list()
	for item in horadric_items_initial:
		horadric_stash.remove_item(item)
		item_stash.add_item(item)

#	Move autofill items from item stash to horadric stash
	for item in autofill_list:
		item_stash.remove_item(item)
		horadric_stash.add_item(item)
