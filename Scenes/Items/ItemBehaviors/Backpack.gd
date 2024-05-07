extends ItemBehavior


# NOTE: original script saves item reference in buff's
# user_int. We don't need to save it because ItemBehavior
# has access to item reference.

var backpack_bt: BuffType
var multiboard: MultiboardValues


func get_autocast_description() -> String:
	var text: String = ""

	text += "Every 150 seconds the next kill will drop an item for sure.\n"

	return text


func on_autocast(_event: Event):
	var tower: Unit = item.get_carrier()
	backpack_bt.apply_only_timed(tower, tower, 1000)


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Search For Item"
	autocast.description = get_autocast_description()
	autocast.icon = "res://Resources/Icons/misc5/gold_icon.tres"
	autocast.caster_art = ""
	autocast.target_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_IMMEDIATE
	autocast.target_self = true
	autocast.cooldown = 150
	autocast.is_extended = false
	autocast.mana_cost = 0
	autocast.buff_type = null
	autocast.target_type = null
	autocast.cast_range = 300
	autocast.auto_range = 0
	autocast.handler = on_autocast

	item.set_autocast(autocast)

	backpack_bt = BuffType.new("backpack_bt", 0, 0, true, self)
	backpack_bt.set_buff_icon("res://Resources/Icons/GenericIcons/pokecog.tres")
	backpack_bt.set_buff_tooltip("Search For Item\nGuarantees an item drop on next kill.")
	backpack_bt.add_event_on_kill(backpack_bt_on_kill)
	
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Items Backpacked")


# NOTE: backpackKill() in original script
func backpack_bt_on_kill(event: Event):
	var B: Buff = event.get_buff()
	var tower: Tower = B.get_buffed_unit()
	var creep: Creep = event.get_target()

	creep.drop_item(tower, false)
	tower.get_player().display_small_floating_text("Backpacked!", tower, Color8(255, 165, 0), 30)
	item.user_int = item.user_int + 1
	B.remove_buff()


func on_create():
#	Total items found
	item.user_int = 0


func on_tower_details() -> MultiboardValues:
	var items_backpacked_text: String = Utils.format_float(item.user_int, 0)
	multiboard.set_value(0, items_backpacked_text)

	return multiboard
