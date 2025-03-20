extends ItemBehavior


# NOTE: in original script, item is used as caster for
# stun_bt. Changed to tower itself because in our engine
# Item is not a Unit.


var stun_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.50, 0.01)


func item_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)


func on_attack(_event: Event):
	var twr: Tower = item.get_carrier()

	if Utils.rand_chance(Globals.synced_rng, 0.15 / twr.get_prop_trigger_chances()):
		CombatLog.log_item_ability(item, null, "Tricky Weapon")

		stun_bt.apply_only_timed(twr, twr, 1)
