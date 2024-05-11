extends ItemBehavior


# NOTE: changed rarity of this item. Original rarity was
# uncommon, changed to common. Original rarity didn't make
# sense because this item is weaker than common rarity "Ring
# of Luck" item.


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.05, 0.0)
