extends Tower

# NOTE: modified this script to use Iterate.next_random()
# instead of re-implementing it. Also removed saving of buff
# caster in userInt because there's no point in doing this
# optimization in godot engine, get_caster() is a cheap
# function call. Could've also replaced the aura with just
# applying buff type permanently to tower but decided to
# leave it as is.


var natac_flashingGraveRandomTarget_BuffType: BuffType


func load_specials():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.10, 0.01)
	add_modifier(modifier)


func attack_random_target(event: Event):
	var b: Buff = event.get_buff()

	var tower: Tower = b.get_caster()
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 2000)
	var random_unit: Unit = iterator.next_random()

	issue_target_order("attack", random_unit)


func tower_init():
	natac_flashingGraveRandomTarget_BuffType = BuffType.create_aura_effect_type("natac_flashingGraveRandomTarget_BuffType", true)
	natac_flashingGraveRandomTarget_BuffType.add_event_on_attack(self, "attack_random_target", 1, 0)
	
	var aura: Aura.Data = Aura.Data.new()
	aura.aura_range = 0
	aura.target_type = TargetType.new(TargetType.PLAYER_TOWERS + TargetType.ELEMENT_STORM)
	aura.target_self = true
	aura.level = 1
	aura.level_add = 0
	aura.power = 1
	aura.power_add = 0
	aura.aura_effect_is_friendly = true
	aura.aura_effect = natac_flashingGraveRandomTarget_BuffType

	add_aura(aura)
