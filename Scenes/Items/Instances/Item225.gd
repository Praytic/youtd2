# Fiery Assassination Arrow
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, 0.20, 0.0)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.20, 0.0)
