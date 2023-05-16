# Assassination Arrow
extends Item


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_CHAMPION, 0.10, 0.004)
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, 0.10, 0.004)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.05, 0.002)
