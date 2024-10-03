extends TowerBehavior


# NOTE: [ORIGINAL_GAME_BUFF] Changed autocast.buff_type
# (null->charm_bt). This fixes issue where tower would
# rebuff a unit which is already buffed.


var charm_bt: BuffType


const BUFF_DURATION: float = 5.0
const BUFF_DURATION_BONUS_AT_25: float = 5.0


func get_tier_stats() -> Dictionary:
	return {
		1: {mod_mana = 0.10, mod_mana_add = 0.006, mod_mana_regen = 0.10, mod_mana_regen_add = 0.006, mod_spell_damage = 0.05, mod_spell_damage_add = 0.003},
		2: {mod_mana = 0.20, mod_mana_add = 0.012, mod_mana_regen = 0.20, mod_mana_regen_add = 0.012, mod_spell_damage = 0.10, mod_spell_damage_add = 0.006},
		3: {mod_mana = 0.30, mod_mana_add = 0.018, mod_mana_regen = 0.30, mod_mana_regen_add = 0.018, mod_spell_damage = 0.15, mod_spell_damage_add = 0.009},
		4: {mod_mana = 0.40, mod_mana_add = 0.024, mod_mana_regen = 0.40, mod_mana_regen_add = 0.024, mod_spell_damage = 0.20, mod_spell_damage_add = 0.012},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MANA_PERC, _stats.mod_mana, _stats.mod_mana_add)
	m.add_modification(Modification.Type.MOD_MANA_REGEN_PERC, _stats.mod_mana_regen, _stats.mod_mana_regen_add)
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, _stats.mod_spell_damage, _stats.mod_spell_damage_add)
	charm_bt = BuffType.new("charm_bt", 0, 0, true, self)
	charm_bt.set_buff_icon("res://resources/icons/generic_icons/charm.tres")
	charm_bt.set_buff_modifier(m)
	charm_bt.set_buff_tooltip("Snake Charm\nIncreases maximum mana, mana regeneration and spell damage.")


func create_autocasts() -> Array[Autocast]:
	var autocast: Autocast = Autocast.make()

	var mod_mana: String = Utils.format_percent(_stats.mod_mana, 2)
	var mod_mana_add: String = Utils.format_percent(_stats.mod_mana_add, 2)
	var mod_mana_regen: String = Utils.format_percent(_stats.mod_mana_regen, 2)
	var mod_mana_regen_add: String = Utils.format_percent(_stats.mod_mana_regen_add, 2)
	var mod_spell_damage: String = Utils.format_percent(_stats.mod_spell_damage, 2)
	var mod_spell_damage_add: String = Utils.format_percent(_stats.mod_spell_damage_add, 2)
	var buff_duration: String = Utils.format_float(BUFF_DURATION, 2)
	var buff_duration_bonus_at_25: String = Utils.format_float(BUFF_DURATION_BONUS_AT_25, 2)

	autocast.title = "Snake Charm"
	autocast.icon = "res://resources/icons/undead/skull_wand_03.tres"
	autocast.description_short = "This unit will increase nearby towers' mana, mana regeneration and spell damage.\n"
	autocast.description = "Increases the target's maximum mana by %s, its mana regeneration by %s and its spell damage by %s. The buff lasts %s seconds.\n" % [mod_mana, mod_mana_regen, mod_spell_damage, buff_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s mana \n" % mod_mana_add \
	+ "+%s mana regeneration\n" % mod_mana_regen_add \
	+ "+%s spell damage\n" % mod_spell_damage_add \
	+ "+%s seconds duration at level 25\n" % buff_duration_bonus_at_25
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 1
	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
	autocast.cast_range = 200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 5
	autocast.is_extended = false
	autocast.mana_cost = 10
	autocast.buff_type = charm_bt
	autocast.buff_target_type = TargetType.new(TargetType.TOWERS)
	autocast.auto_range = 200
	autocast.handler = on_autocast

	return [autocast]


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()

	var duration: float = BUFF_DURATION
	if level == 25:
		duration += BUFF_DURATION_BONUS_AT_25

	charm_bt.apply_custom_timed(tower, target, level, duration)
