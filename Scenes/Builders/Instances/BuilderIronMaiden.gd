extends Builder


func _init():
	PortalLives.modify_portal_lives(50)
	WaveLevel.changed.connect(_on_wave_level_changed)


func _on_wave_level_changed():
	var portal_lives: float = PortalLives.get_current()

# 	NOTE: the tooltip says 50% and 10%, but that is in
# 	absolute terms without considering +50% to base lives
# 	from Iron Maiden. 50% means 50, not 0.5 * 150 = 75. This
# 	is how it works in original game.
	var regen_amount: float
	if portal_lives < 10:
		regen_amount = 1
	elif portal_lives < 50:
		regen_amount = 2
	else:
		regen_amount = 0

	PortalLives.modify_portal_lives(regen_amount)

# 	NOTE: original game doesn't have this message but I
# 	thought that it would be useful to add it.
	if regen_amount != 0:
		var regen_amount_string: String = Utils.format_percent(regen_amount / 100, 1)
		Messages.add_normal("You gain %s lives thanks to the Iron Maiden." % regen_amount_string)
