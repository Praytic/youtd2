extends TowerBehavior


var aura_bt: BuffType
var forklight_st: SpellType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var glare: AbilityInfo = AbilityInfo.new()
	glare.name = "Glare"
	glare.description_short = "The Eye launches a forked lightning on every attack.\n"
	glare.description_full = "The Eye launches a forked lightning on every attack at the cost of 40 mana. The forked lightning deals 500 plus 1.5% of the original target's current health as spell damage. The forked lightning hits up to 3 creeps.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+120 spell damage\n"
	list.append(glare)

	var static_field: AbilityInfo = AbilityInfo.new()
	static_field.name = "Static Field - Aura"
	static_field.description_short = "Towers in range have their damage increased when attacking immune creeps.\n"
	static_field.description_full = "Towers within 350 range of this tower have their damage increased by 20% when attacking immune creeps.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+1% damage\n"
	list.append(static_field)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_BOSS, -0.10, 0.0)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.set_buff_icon("res://Resources/Textures/GenericIcons/rss.tres")
	aura_bt.add_event_on_damage(aura_bt_on_damage)
	aura_bt.set_buff_tooltip("Static Field Aura\nIncreases damage dealt to immune creeps.")

	forklight_st = SpellType.new("@@0@@", "forkedlightning", 1, self)
	forklight_st.data.forked_lightning.damage = 1.0
	forklight_st.data.forked_lightning.target_count = 3


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()
	aura.aura_range = 350
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.power = 0
	aura.power_add = 1
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
