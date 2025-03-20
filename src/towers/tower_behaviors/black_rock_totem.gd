extends TowerBehavior


# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Blackrock's Totem"=>"Black Rock Totem"


var fighter_totem_bt: BuffType
var demonic_fire_bt: BuffType
var shamanic_totem_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func tower_init():
	fighter_totem_bt = BuffType.new("fighter_totem_bt", 5, 0.2, true, self)
	var figher_totem_bt_mod: Modifier = Modifier.new()
	figher_totem_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.10, 0.004)
	figher_totem_bt_mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.05, 0.002)
	figher_totem_bt_mod.add_modification(Modification.Type.MOD_ATK_CRIT_DAMAGE, 0.50, 0.020)
	fighter_totem_bt.set_buff_modifier(figher_totem_bt_mod)
	fighter_totem_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	fighter_totem_bt.set_buff_tooltip("Fighter Totem\nIncreases attack damage, crit chance and crit damage.")

	shamanic_totem_bt = BuffType.new("shamanic_totem_bt", 5, 0.2, true, self)
	var shamanic_totem_bt_mod: Modifier = Modifier.new()
	shamanic_totem_bt_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.10, 0.004)
	shamanic_totem_bt.set_buff_modifier(shamanic_totem_bt_mod)
	shamanic_totem_bt.set_buff_icon("res://resources/icons/generic_icons/aquarius.tres")
	shamanic_totem_bt.set_buff_tooltip("Shamanic Totem\nIncreases spell damage.")

	demonic_fire_bt = BuffType.new("demonic_fire_bt", 5, 0.2, false, self)
	demonic_fire_bt.set_buff_icon("res://resources/icons/generic_icons/flame.tres")
	demonic_fire_bt.set_buff_tooltip("Demonic Fire\nChance to permanently increase damage taken from Fire towers.")
	demonic_fire_bt.add_event_on_damaged(demonic_fire_bt_on_damaged)


func on_attack(_event: Event):
	var level: int = tower.get_level()
	var chance: float = 0.15 + 0.002 * level

	if !tower.calc_chance(chance):
		return

	CombatLog.log_ability(tower, null, "Fighter Totem")

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)

	while true:
		var other_tower: Tower = it.next()

		if other_tower == null:
			break

		fighter_totem_bt.apply(tower, other_tower, level)


func on_autocast(event: Event):
	var level: int = tower.get_level()
	var target: Creep = event.get_target()
	var target_is_boss: bool = target.get_size() >= CreepSize.enm.BOSS
	var shamanic_totem_chance: float = 0.30 + 0.004 * level
	var restore_mana_ratio: float = 0.075 + 0.003 * level

	var mod_dmg_from_fire_value: float
	if target_is_boss:
		mod_dmg_from_fire_value = 0.01 + 0.0004 * level
	else:
		mod_dmg_from_fire_value = 0.03 + 0.0008 * level

	var buff: Buff = demonic_fire_bt.apply(tower, target, level)
	buff.user_real = mod_dmg_from_fire_value

	if !tower.calc_chance(shamanic_totem_chance):
		return

	CombatLog.log_ability(tower, null, "Shamanic Totem")

	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 500)

	while true:
		var other_tower: Tower = it.next()

		if other_tower == null:
			break

		shamanic_totem_bt.apply(tower, other_tower, level)

		if other_tower != tower:
			other_tower.add_mana_perc(restore_mana_ratio)


func demonic_fire_bt_on_damaged(event: Event):
	var buff: Buff = event.get_buff()
	var creep: Creep = buff.get_buffed_unit()
	var mod_value: float = buff.user_real

	if creep.calc_chance(0.2):
		creep.modify_property(Modification.Type.MOD_DMG_FROM_FIRE, mod_value)
