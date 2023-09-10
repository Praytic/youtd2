# Seeker's Arcane Oil
extends Item


const SEEKER_ARCANE_OIL_ID: int = 1019


func get_extra_tooltip_text() -> String:
	return "[color=GOLD]This oil also applies to neighbor towers![/color]"


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.05, 0.002)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.05, 0.002)


func on_pickup():
	Item1018.seeker_oil_on_pickup(self, SEEKER_ARCANE_OIL_ID)
