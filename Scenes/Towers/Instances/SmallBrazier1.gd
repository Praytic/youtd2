extends Tower


# NOTE: this tower's tooltip in original game includes
# innate stats in some cases
# crit chance = yes
# crit chance add = no
# crit dmg = yes
# crit dmg add = no
func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.1375, 0.015)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.45, 0.03)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 1.0, 0.0)
