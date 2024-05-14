extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 200


# NOTE: tooltip in original game includes innate stats in some cases
# crit chance = yes
# crit chance add = no
# crit dmg = yes
# crit dmg add = no
func load_specials(modifier: Modifier):
	tower.set_attack_style_bounce(4, 0.10)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.1375, 0.005)
	modifier.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.25, 0.05)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2, 0.0)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/biceps.tres")
	aura_bt.set_buff_tooltip("Green Dragon Force Aura\nIncreases multicrit.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Green Dragon Force"
	aura.icon = "res://Resources/Icons/animals/dragon_02.tres"
	aura.description_short = "Increases multicrit of towers in range.\n"
	aura.description_full = "Increases the multicrit of towers in %d range by 2.\n" % AURA_RANGE

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
	aura.aura_effect = aura_bt
	return [aura]
