extends ButtonStatusCard


@export var _items_status_panel: ShortResourceStatusPanel
@export var _oils_status_panel: ShortResourceStatusPanel
@export var _commons_status_panel: ShortResourceStatusPanel
@export var _uncommons_status_panel: ShortResourceStatusPanel
@export var _rares_status_panel: ShortResourceStatusPanel
@export var _uniques_status_panel: ShortResourceStatusPanel


#########################
###       Public      ###
#########################

func connect_to_local_player(local_player: Player):
	var item_stash: ItemContainer = local_player.get_item_stash()
	item_stash.items_changed.connect(_on_item_stash_changed)


#########################
###     Callbacks     ###
#########################

func _on_item_stash_changed():
	var local_player: Player = PlayerManager.get_local_player()
	var item_stash: ItemContainer = local_player.get_item_stash()
	var item_list: Array[Item] = item_stash.get_item_list()
	var items_count: int = Utils.filter_item_list(item_list, [], [ItemType.enm.REGULAR]).size()
	var oils_count: int = Utils.filter_item_list(item_list, [], [ItemType.enm.CONSUMABLE, ItemType.enm.OIL]).size()
	var commons_count: int = Utils.filter_item_list(item_list, [Rarity.enm.COMMON], []).size()
	var uncommons_count: int = Utils.filter_item_list(item_list, [Rarity.enm.UNCOMMON], []).size()
	var rares_count: int = Utils.filter_item_list(item_list, [Rarity.enm.RARE], []).size()
	var uniques_count: int = Utils.filter_item_list(item_list, [Rarity.enm.UNIQUE], []).size()
	
	_items_status_panel.set_count(items_count)
	_oils_status_panel.set_count(oils_count)
	_commons_status_panel.set_count(commons_count)
	_uncommons_status_panel.set_count(uncommons_count)
	_rares_status_panel.set_count(rares_count)
	_uniques_status_panel.set_count(uniques_count)
