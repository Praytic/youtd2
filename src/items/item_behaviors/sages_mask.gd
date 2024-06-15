extends ItemBehavior

# NOTE: this item was named "Sobi Mask" in original youtd


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.86, 0.0)
