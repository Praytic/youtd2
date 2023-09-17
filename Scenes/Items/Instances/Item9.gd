# Wanted List
extends Item


# NOTE: original script saves item reference in buff's
# user_int. This doesn't work due to typing. We don't need
# to save it anyway because item is equal to "self".

var boekie_backpackBuff: BuffType
var boekie_backpackMB: MultiboardValues


func get_autocast_description() -> String:
	var text: String = ""

	text += "Every 150 seconds the next kill will drop an item for sure.\n"

	return text


func on_autocast(_event: Event):
	var itm: Item = self

	var tower: Unit = itm.get_carrier()
	boekie_backpackBuff.apply_only_timed(tower, tower, 1000)


func item_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Search For Item"
	autocast.description = get_autocast_description()
	autocast.icon = "res://Resources/Textures/gold.tres"
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

	set_autocast(autocast)

	boekie_backpackBuff = BuffType.new("boekie_backpackBuff", 0, 0, true, self)
	boekie_backpackBuff.set_buff_icon("@@0@@")
	boekie_backpackBuff.add_event_on_kill(backpack_kill)
	boekie_backpackMB = MultiboardValues.new(1)
	boekie_backpackMB.set_key(0, "Items Backpacked")


func backpack_kill(event: Event):
	var B: Buff = event.get_buff()
	var tower: Tower = B.get_buffed_unit()
	var creep: Creep = event.get_target()
	var itm: Item = self

	creep.drop_item(tower, false)
	tower.get_player().display_small_floating_text("Backpacked!", tower, 255, 165, 0, 30)
	itm.user_int = itm.user_int + 1
	B.remove_buff()


func on_create():
	var itm: Item = self
#	Total items found
	itm.user_int = 0


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	var items_backpacked_text: String = Utils.format_float(itm.user_int, 0)
	boekie_backpackMB.set_value(0, items_backpacked_text)

	return boekie_backpackMB
