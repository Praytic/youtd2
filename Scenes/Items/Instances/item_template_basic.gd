# Template Item Basic
extends Item

# NOTE: not a real item script, used as a template for item
# scripts. Use for basic items that only have modifiers.


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
