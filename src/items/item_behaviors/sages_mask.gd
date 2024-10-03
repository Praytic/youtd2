extends ItemBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Sobi Mask"=>"Sage's Mask"


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, 0.86, 0.0)
