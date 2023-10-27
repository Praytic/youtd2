# Seeker's Oil
class_name Item1018 extends Item


# NOTE: this range covers all towers in 3x3 grid around
# carrier. In original game this oil could hit 4+3+4 in
# honeycomb pattern but currently in youtd2 you can't build
# honeycomb patterns.
static var SEEKER_OIL_RANGE: float = 250
const SEEKER_OIL_ID: int = 1018


func get_ability_description() -> String:
	return "[color=GOLD]This oil also applies to neighbor towers![/color]"


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_CHANCE_ON_KILL, 0.02, 0.0008)
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.02, 0.0008)


func on_pickup():
	Item1018.seeker_oil_on_pickup(self, SEEKER_OIL_ID)


static func seeker_oil_on_pickup(original_oil: Item, oil_id: int):
# 	NOTE: hackfix alert! The _is_oil_and_was_applied_already
# 	flag is used to know when we are transferring oils from
# 	one tower to another, either when towers get upgraded or
# 	transformed. In such cases, we do not do the aoe effect
# 	of seeker oil again - we only transfer the oil from old
# 	tower to new tower.
	if original_oil._is_oil_and_was_applied_already:
		return

	var is_original_oil: bool = original_oil.user_int == 0

	if !is_original_oil:
		return

	var carrier: Tower = original_oil.get_carrier()

	var towers_in_range: Iterate = Iterate.over_units_in_range_of_caster(carrier, TargetType.new(TargetType.TOWERS), SEEKER_OIL_RANGE)

	while towers_in_range.count() > 0:
		var neighbor: Tower = towers_in_range.next()

		if neighbor == carrier:
			continue

		var oil_for_neighbor: Item = Item.create(null, oil_id, carrier.position)

#		NOTE: set user_int to 1 to mark this oil to stop recursion
		oil_for_neighbor.user_int = 1

		oil_for_neighbor.pickup(neighbor)
