extends TowerBehavior


var aura_bt: BuffType
var forklight_st: SpellType

const AURA_RANGE: int = 350


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var glare: AbilityInfo = AbilityInfo.new()
	glare.name = "Glare"
	glare.icon = "res://resources/icons/magic/eye_blue.tres"
	glare.description_short = "Whenever this tower attacks, it launches a forked lightning, dealing spell damage.\n"
	glare.description_full = "Whenever this tower attacks, it launches a forked lightning at the cost of 40 mana. The forked lightning deals 500 plus 1.5% of the original target's current health as spell damage. The forked lightning hits up to 3 creeps.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+120 spell damage\n"
	list.append(glare)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, -0.10, 0.0)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	aura_bt.add_event_on_damage(aura_bt_on_damage)
	aura_bt.set_buff_tooltip("Static Field Aura\nIncreases damage dealt to immune creeps.")

	forklight_st = SpellType.new(SpellType.Name.FORKED_LIGHTNING, 1, self)
	forklight_st.data.forked_lightning.damage = 1.0
	forklight_st.data.forked_lightning.target_count = 3


func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Static Field"
	aura.icon = "res://resources/icons/dioramas/book_display.tres"
	aura.description_short = "Towers in range have their attack damage increased when attacking immune creeps.\n"
	aura.description_full = "Towers within %d range of this tower have their attack damage increased by 20%% when attacking immune creeps.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt

	return [aura]


func on_attack(event: Event):
	var creep: Creep = event.get_target()
	var creep_health: float = creep.get_health()
	var tower_mana: float = tower.get_mana()
	var level: int = tower.get_level()
	var glare_damage: float = 500 + 120 * level + 0.015 * creep_health

	if tower_mana < 40:
		return

	tower.subtract_mana(40, false)

	forklight_st.target_cast_from_caster(tower, creep, glare_damage, tower.calc_spell_crit_no_bonus())


func aura_bt_on_damage(event: Event):
	var target: Unit = event.get_target()
	var damage_multiplier: float = 1.2 + 0.01 * tower.get_level()

	if target.is_immune():
		event.damage *= damage_multiplier
