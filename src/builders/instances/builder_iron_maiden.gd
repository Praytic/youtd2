extends Builder


func apply_to_player(player: Player):
	player.get_team().modify_lives(50)


func apply_wave_finished_effect(player: Player):
	var portal_lives: float = player.get_team().get_lives_percent()

# 	NOTE: the tooltip says 50% and 10%, but that is in
# 	absolute terms without considering +50% to base lives
# 	from Iron Maiden. 50% means 50, not 0.5 * 150 = 75. This
# 	is how it works in original game.
	var regen_amount: float
	if portal_lives < 10:
		regen_amount = 2
	elif portal_lives < 50:
		regen_amount = 1
	else:
		regen_amount = 0

	player.get_team().modify_lives(regen_amount)

# 	NOTE: original game doesn't have this message but I
# 	thought that it would be useful to add it.
	if regen_amount != 0:
		var regen_amount_string: String = Utils.format_percent(regen_amount / 100, 1)
		Messages.add_normal(player, tr("MESSAGE_IRON_MAIDEN").format({REGENED_LIVES = regen_amount_string}))
