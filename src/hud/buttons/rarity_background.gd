class_name RarityBackground extends PanelContainer


# Used in button scenes to indicate rarity.


func set_rarity(rarity: Rarity.enm):
	var theme_type_variation_name: String
	match rarity:
		Rarity.enm.COMMON:
			theme_type_variation_name = "CommonRarityPanelContainer"
		Rarity.enm.UNCOMMON:
			theme_type_variation_name = "UncommonRarityPanelContainer"
		Rarity.enm.RARE:
			theme_type_variation_name = "RareRarityPanelContainer"
		Rarity.enm.UNIQUE:
			theme_type_variation_name = "UniqueRarityPanelContainer"
		_:
			theme_type_variation_name = ""
	
	theme_type_variation = theme_type_variation_name
