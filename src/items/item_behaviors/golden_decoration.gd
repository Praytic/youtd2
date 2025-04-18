extends ItemBehavior


var multiboard: MultiboardValues


func item_init():
	multiboard = MultiboardValues.new(1)
	var interest_bonus_label: String = tr("Q7IE")
	multiboard.set_key(0, interest_bonus_label)


func on_create():
	item.user_real = 0


func on_drop():
	item.get_player().modify_interest_rate(-item.user_real)


func on_pickup():
	var tower: Tower = item.get_carrier()
	item.user_real = 0.004 * (tower.get_gold_cost() / 2500.0)
	item.get_player().modify_interest_rate(item.user_real)


func on_tower_details() -> MultiboardValues:
	multiboard.set_value(0, Utils.format_percent(item.user_real, 3))
	return multiboard
