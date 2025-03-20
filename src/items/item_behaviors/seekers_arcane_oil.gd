extends ItemBehavior


const SEEKER_ARCANE_OIL_ID: int = 1019


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.05, 0.002)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.05, 0.002)


func on_pickup():
	SeekersOil.seeker_oil_on_pickup(item, SEEKER_ARCANE_OIL_ID)
