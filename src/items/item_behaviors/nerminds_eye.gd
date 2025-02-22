extends ItemBehavior


var nermind_bt: BuffType


func item_init():
	nermind_bt = MagicalSightBuff.new("nermind_bt", 750, self)
	nermind_bt.set_buff_tooltip("Nermind's Eye\nReveals invisible units in range.")


func on_pickup():
	var carrier: Unit = item.get_carrier()
	nermind_bt.apply_to_unit_permanent(carrier, carrier, 0)	
