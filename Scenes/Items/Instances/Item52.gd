# Zombie Head
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.75, 0.01)
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, -0.50, 0.0)
