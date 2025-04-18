extends ItemBehavior


const SEEKER_ARCANE_OIL_ID: int = 1019


func on_pickup():
	SeekersOil.seeker_oil_on_pickup(item, SEEKER_ARCANE_OIL_ID)
