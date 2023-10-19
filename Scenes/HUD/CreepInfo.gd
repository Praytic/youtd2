extends GridContainer


# Movespeed
@export var _base_movespeed: Label
@export var _movespeed_bonus: Label
@export var _movespeed_bonus_perc: Label
@export var _overall_movespeed: Label
@export var _damage_reduction: Label

# Armor
@export var _base_armor: Label
@export var _armor_bonus: Label
@export var _armor_bonus_perc: Label
@export var _overall_armor: Label

# Damage from element
@export var _dmg_from_astral: Label
@export var _dmg_from_darkness: Label
@export var _dmg_from_nature: Label
@export var _dmg_from_ice: Label
@export var _dmg_from_fire: Label
@export var _dmg_from_storm: Label
@export var _dmg_from_iron: Label

# Defense
@export var _dmg_from_attacks: Label
@export var _dmg_from_spells: Label

# Health
@export var _base_health: Label
@export var _health_bonus: Label
@export var _health_bonus_perc: Label
@export var _overall_health: Label
@export var _base_health_regen: Label
@export var _health_regen_bonus: Label
@export var _health_regen_bonus_perc: Label
@export var _overall_health_regen: Label

# Mana
@export var _base_mana: Label
@export var _mana_bonus: Label
@export var _mana_bonus_perc: Label
@export var _overall_mana: Label
@export var _base_mana_regen: Label
@export var _mana_regen_bonus: Label
@export var _mana_regen_bonus_perc: Label
@export var _overall_mana_regen: Label

# Misc
@export var _bounty_ratio: Label
@export var _exp_ratio: Label
@export var _item_drop_ratio: Label
@export var _item_quality_ratio: Label
@export var _buff_duration: Label
@export var _debuff_duration: Label

func _ready():
	SelectUnit.selected_unit_changed.connect(_on_selected_unit_changed)


func _on_selected_unit_changed(_prev_unit: Unit):
	update_text()


func _on_refresh_timer_timeout():
	update_text()


func update_text():
	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if !selected_unit is Creep:
		return
	
	var creep: Creep = selected_unit as Creep

#	Movespeed
	var base_movespeed: float = creep.get_base_movespeed()
	var base_movespeed_string: String = Utils.format_float(base_movespeed, 0)
	_base_movespeed.set_text(base_movespeed_string)

	var movespeed_bonus: float = creep.get_prop_move_speed_absolute()
	var movespeed_bonus_string: String = Utils.format_float(movespeed_bonus, 0)
	_movespeed_bonus.set_text(movespeed_bonus_string)

	var movespeed_bonus_perc: float = creep.get_prop_move_speed() - 1.0
	var movespeed_bonus_perc_string: String = Utils.format_percent(movespeed_bonus_perc, 0)
	_movespeed_bonus_perc.set_text(movespeed_bonus_perc_string)

	var overall_movespeed: float = creep.get_current_movespeed()
	var overall_movespeed_string: String = Utils.format_float(overall_movespeed, 0)
	_overall_movespeed.set_text(overall_movespeed_string)

#	Armor
	var base_armor: float = creep.get_base_armor()
	var base_armor_string: String = Utils.format_float(base_armor, 1)
	_base_armor.set_text(base_armor_string)

	var armor_bonus: float = creep.get_base_armor_bonus()
	var armor_bonus_string: String = Utils.format_float(armor_bonus, 1)
	_armor_bonus.set_text(armor_bonus_string)

	var armor_bonus_perc: float = creep.get_base_armor_bonus_percent() - 1.0
	var armor_bonus_perc_string: String = Utils.format_percent(armor_bonus_perc, 0)
	_armor_bonus_perc.set_text(armor_bonus_perc_string)

	var overall_armor: float = creep.get_overall_armor()
	var overall_armor_string: String = Utils.format_float(overall_armor, 1)
	_overall_armor.set_text(overall_armor_string)

	var damage_reduction: float = creep.get_current_armor_damage_reduction()
	var damage_reduction_string: String = Utils.format_percent(damage_reduction, 0)
	_damage_reduction.set_text(damage_reduction_string)

#	Defense
	var dmg_from_attacks: float = creep.get_prop_atk_damage_received()
	var dmg_from_attacks_string: String = Utils.format_percent(dmg_from_attacks, 0)
	_dmg_from_attacks.set_text(dmg_from_attacks_string)

	var dmg_from_spells: float = creep.get_prop_spell_damage_received()
	var dmg_from_spells_string: String = Utils.format_percent(dmg_from_spells, 0)
	_dmg_from_spells.set_text(dmg_from_spells_string)

#	Damage from element
	var dmg_from_astral: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_ASTRAL]
	var dmg_from_astral_string: String = Utils.format_percent(dmg_from_astral, 0)
	_dmg_from_astral.set_text(dmg_from_astral_string)

	var dmg_from_darkness: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_DARKNESS]
	var dmg_from_darkness_string: String = Utils.format_percent(dmg_from_darkness, 0)
	_dmg_from_darkness.set_text(dmg_from_darkness_string)

	var dmg_from_nature: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_NATURE]
	var dmg_from_nature_string: String = Utils.format_percent(dmg_from_nature, 0)
	_dmg_from_nature.set_text(dmg_from_nature_string)

	var dmg_from_ice: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_ICE]
	var dmg_from_ice_string: String = Utils.format_percent(dmg_from_ice, 0)
	_dmg_from_ice.set_text(dmg_from_ice_string)

	var dmg_from_fire: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_FIRE]
	var dmg_from_fire_string: String = Utils.format_percent(dmg_from_fire, 0)
	_dmg_from_fire.set_text(dmg_from_fire_string)

	var dmg_from_storm: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_STORM]
	var dmg_from_storm_string: String = Utils.format_percent(dmg_from_storm, 0)
	_dmg_from_storm.set_text(dmg_from_storm_string)

	var dmg_from_iron: float = creep._mod_value_map[Modification.Type.MOD_DMG_FROM_IRON]
	var dmg_from_iron_string: String = Utils.format_percent(dmg_from_iron, 0)
	_dmg_from_iron.set_text(dmg_from_iron_string)

# 	Health
	var base_health: float = creep.get_base_health()
	var base_health_string: String = Utils.format_float(base_health, 1)
	_base_health.set_text(base_health_string)

	var health_bonus: float = creep.get_base_health_bonus()
	var health_bonus_string: String = Utils.format_float(health_bonus, 1)
	_health_bonus.set_text(health_bonus_string)

	var health_bonus_perc: float = creep.get_base_health_bonus_percent() - 1.0
	var health_bonus_perc_string: String = Utils.format_percent(health_bonus_perc, 0)
	_health_bonus_perc.set_text(health_bonus_perc_string)

	var overall_health: float = creep.get_overall_health()
	var overall_health_string: String = Utils.format_float(overall_health, 1)
	_overall_health.set_text(overall_health_string)

	var base_health_regen: float = creep.get_base_health_regen()
	var base_health_regen_string: String = Utils.format_float(base_health_regen, 1)
	_base_health_regen.set_text(base_health_regen_string)

	var health_regen_bonus: float = creep.get_base_health_regen_bonus()
	var health_regen_bonus_string: String = Utils.format_float(health_regen_bonus, 1)
	_health_regen_bonus.set_text(health_regen_bonus_string)

	var health_regen_bonus_perc: float = creep.get_base_health_regen_bonus_percent() - 1.0
	var health_regen_bonus_perc_string: String = Utils.format_percent(health_regen_bonus_perc, 0)
	_health_regen_bonus_perc.set_text(health_regen_bonus_perc_string)

	var overall_health_regen: float = creep.get_overall_health_regen()
	var overall_health_regen_string: String = Utils.format_float(overall_health_regen, 1)
	_overall_health_regen.set_text(overall_health_regen_string)

# 	Mana
	var base_mana: float = creep.get_base_mana()
	var base_mana_string: String = Utils.format_float(base_mana, 1)
	_base_mana.set_text(base_mana_string)

	var mana_bonus: float = creep.get_base_mana_bonus()
	var mana_bonus_string: String = Utils.format_float(mana_bonus, 1)
	_mana_bonus.set_text(mana_bonus_string)

	var mana_bonus_perc: float = creep.get_base_mana_bonus_percent() - 1.0
	var mana_bonus_perc_string: String = Utils.format_percent(mana_bonus_perc, 0)
	_mana_bonus_perc.set_text(mana_bonus_perc_string)

	var overall_mana: float = creep.get_overall_mana()
	var overall_mana_string: String = Utils.format_float(overall_mana, 1)
	_overall_mana.set_text(overall_mana_string)

	var base_mana_regen: float = creep.get_base_mana_regen()
	var base_mana_regen_string: String = Utils.format_float(base_mana_regen, 1)
	_base_mana_regen.set_text(base_mana_regen_string)

	var mana_regen_bonus: float = creep.get_base_mana_regen_bonus()
	var mana_regen_bonus_string: String = Utils.format_float(mana_regen_bonus, 1)
	_mana_regen_bonus.set_text(mana_regen_bonus_string)

	var mana_regen_bonus_perc: float = creep.get_base_mana_regen_bonus_percent() - 1.0
	var mana_regen_bonus_perc_string: String = Utils.format_percent(mana_regen_bonus_perc, 0)
	_mana_regen_bonus_perc.set_text(mana_regen_bonus_perc_string)

	var overall_mana_regen: float = creep.get_overall_mana_regen()
	var overall_mana_regen_string: String = Utils.format_float(overall_mana_regen, 1)
	_overall_mana_regen.set_text(overall_mana_regen_string)

#	Misc
	var bounty_ratio: float = creep.get_prop_bounty_granted()
	var bounty_ratio_string: String = Utils.format_percent(bounty_ratio, 0)
	_bounty_ratio.set_text(bounty_ratio_string)

	var exp_ratio: float = creep.get_prop_exp_granted()
	var exp_ratio_string: String = Utils.format_percent(exp_ratio, 0)
	_exp_ratio.set_text(exp_ratio_string)

	var item_drop_ratio: float = creep.get_item_drop_ratio_on_death()
	var item_drop_ratio_string: String = Utils.format_percent(item_drop_ratio, 0)
	_item_drop_ratio.set_text(item_drop_ratio_string)

	var item_quality_ratio: float = creep.get_item_quality_ratio_on_death()
	var item_quality_ratio_string: String = Utils.format_percent(item_quality_ratio, 0)
	_item_quality_ratio.set_text(item_quality_ratio_string)

	var buff_duration: float = creep.get_prop_buff_duration()
	var buff_duration_string: String = Utils.format_percent(buff_duration, 0)
	_buff_duration.set_text(buff_duration_string)

	var debuff_duration: float = creep.get_prop_debuff_duration()
	var debuff_duration_string: String = Utils.format_percent(debuff_duration, 0)
	_debuff_duration.set_text(debuff_duration_string)
