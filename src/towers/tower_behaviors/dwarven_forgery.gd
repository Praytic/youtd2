extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 550


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.50, 0.01)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.15, 0.004)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	aura_bt.set_buff_tooltip("Dwarven Polish Aura\nIncreases quality of dropped items.")


func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Dwarven Polish"
	aura.icon = "res://resources/icons/swords/greatsword_04.tres"
	aura.description_short = "Increases item quality of towers in range.\n"
	aura.description_full = "Increases the item quality of friendly towers in %d range including itself by 15%%.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.4% item quality\n"
	
	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]
