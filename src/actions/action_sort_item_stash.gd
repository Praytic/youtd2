class_name ActionSortItemStash


# NOTE: this action is not confirmed to be 100% necessary
# but better to be safe and avoid desyncs. The sort function
# changes the order of items which can affect gameplay logic
# and cause desyncs if done outside Action.


static func make() -> Action:
	var action: Action = Action.new({
		Action.Field.TYPE: Action.Type.SORT_ITEM_STASH,
		})

	return action


static func execute(_action: Dictionary, player: Player):
	var item_stash: ItemContainer = player.get_item_stash()
	item_stash.sort_items_by_type_rarity_and_levels()
