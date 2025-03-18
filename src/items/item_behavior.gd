class_name ItemBehavior extends Node


# ItemBehavior is used to implement behavior for a
# particular item. Each item has it's own ItemBehavior
# script which is attached to Item base class to create a
# complete item.


var item: Item


#########################
###       Public      ###
#########################

func init(item_arg: Item, modifier: Modifier, triggers_buff_type: BuffType):
	item = item_arg

	load_modifier(modifier)
	item_init()

#	NOTE: Order is important here! Auras and autocasts must
#	be loaded after calling item_init() because buffs are
#	setup in item_init() and auras/autocasts rely on buffs.
	var item_id: int = item.get_id()
	var aura_id_list: Array = ItemProperties.get_aura_id_list(item_id)
	for aura_id in aura_id_list:
		var aura_type: AuraType = AuraType.make_aura_type(aura_id, self)
		item.add_aura(aura_type)

	var autocast_id_list: Array = ItemProperties.get_autocast_id_list(item_id)
	for autocast_id in autocast_id_list:
		var autocast: Autocast = Autocast.make_from_id(autocast_id, self)
		item.set_autocast(autocast)

	load_triggers(triggers_buff_type)
	on_create()


# Override this in subclass to attach trigger handlers to
# triggers buff passed in the argument.
func load_triggers(_triggers: BuffType):
	pass


# Override in subclass to define the modifier that will be
# added to carrier of the item
func load_modifier(_modifier_arg: Modifier):
	pass


# Override in subclass to initialize subclass item
# NOTE: item.init() in JASS
func item_init():
	pass


# Override in subclass script to implement the effect that
# should happen when the item is consumed.
func on_consume():
	pass


# NOTE: item.onCreate() in JASS
func on_create():
	pass


# NOTE: item.onPickup() in JASS
func on_pickup():
	pass


# NOTE: item.onDrop() in JASS
func on_drop():
	pass


# NOTE: item.onTowerDetails() in JASS
func on_tower_details() -> MultiboardValues:
	return null
