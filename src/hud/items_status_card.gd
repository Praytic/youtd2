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

func set_items(item_list: Array[Item]):
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
