# Golden Decoration
extends Item


var interest_bonus_mb: MultiboardValues

func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Rich[/color]\n"
	text += "Whilst carried by a tower, this item increases the interest rate of the player by [0.4 x carrier's goldcost / 2500]%.\n"

	return text


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.10, 0.004)


func item_init():
	interest_bonus_mb = MultiboardValues.new(1)
	interest_bonus_mb.set_key(0, "Interest Bonus")


func on_create():
	var itm: Item = self
	itm.user_real = 0


func on_drop():
	var itm: Item = self
	itm.get_player().modify_interest_rate(-itm.user_real)


func on_pickup():
	var itm: Item = self
	var tower: Tower = itm.get_carrier()
	itm.user_real = 0.004 * (tower.get_gold_cost() / 2500.0)
	itm.get_player().modify_interest_rate(itm.user_real)


func on_tower_details() -> MultiboardValues:
	var itm: Item = self
	interest_bonus_mb.set_value(0, Utils.format_percent(itm.user_real, 3))
	return interest_bonus_mb
