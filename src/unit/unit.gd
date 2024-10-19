class_name Unit
extends Node2D

# Unit is a base class for Towers and Creeps. Keeps track of
# buffs and modifications. Emits signals for events which are used by buffs.

# NOTE: can't use static typing for Buff because of cyclic
# dependency

# NOTE: see comments in buff_type.gd for detailed info about
# unit events. For example, add_event_on_level_changed()
# function.
signal level_changed(level_increased: bool)
signal attack(event)
signal attacked(event)
signal dealt_damage(event)
signal damaged(event)
signal kill(event)
signal death(event)
signal health_changed()
signal mana_changed()
signal spell_casted(event: Event)
signal spell_targeted(event: Event)
signal buff_list_changed()
signal buff_group_changed()
signal selected_changed()
signal hovered_changed()


enum DamageSource {
	Attack,
	Spell
}

enum BodyPart {
	OVERHEAD,
	HEAD,
	CHEST,
	ORIGIN
}


const REGEN_PERIOD: float = 1.0

# NOTE: need to have "_unit_" prefix in names to avoid
# conflicts with variables in subclasses
var _visual_node: Node2D = null
var _unit_sprite: Node2D = null
var _unit_sprite_parent: Node2D = null
var _unit_selection_outline_parent: Node2D = null
var _sprite_dimensions: Vector2 = Vector2(100, 100)

# NOTE: userInt/userInt2/... in JASS
var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

# NOTE: crit bonus in terms of number of crits. The logic is
# different for attack vs spell. For attack crits, the bonus
# is applied only to normal tower attacks. Bonus is not
# applied to do_attack_damage() called from other scripts.
# This is because it would be confusing for an item like
# "every 5th attack is critical" to produce no visible
# change because tower is consuming crit bonus via some
# other attack damage which is not visible to the player.
# For spells, the bonus is applied to all instances of spell
# damage, which includes calls to do_spell_damage(), spells
# casted using Cast class, etc.
var _bonus_crit_count_for_next_attack: int = 0
var _bonus_crit_ratio_for_next_attack: float = 0.0
var _bonus_crit_count_for_next_spell: int = 0

var _level: int = 0
var _buff_map: Dictionary
var _buff_list: Array[Buff] = []
var _direct_modifier_list: Array
var _base_health: float = 100.0
var _health: float = 0.0
var _lowest_health: float = 0.0
var _base_health_regen: float = 0.0
var _immune: bool = false
var _selected: bool = false
var _hovered: bool = false
var _experience: float = 0.0
var _mana: float = 0.0
var _base_mana: float = 0.0
var _base_mana_regen: float = 0.0
var _base_armor: float = 0.0
var _kill_count: int = 0
var _best_hit: float = 0.0
var _damage_dealt_total: float = 0.0
var _damage_dealt_to_wave_map: Dictionary = {}
var _ethereal_count: int = 0
var _silence_count: int = 0
var _stun_count: int = 0
var _stun_effect_id: int = -1
var _autocast_list: Array[Autocast] = []
var _aura_list: Array[Aura] = []
var _target_bitmask: int = 0x0
var _buff_groups: Dictionary = {}
var _player: Player = null
static var _uid_max: int = 1
var _uid: int = 0
# NOTE: up axis is positive z, down axis is negative z.
var _position_wc3: Vector3
var _total_stun_duration: float = 0.0

var _selection_indicator: Node = null
var _unit_selection_outline: Node = null


# NOTE: logic for default values is the following. If
# property is multiplied, then it's default is 1.0 so that
# by default it doesn't change anything. If property is
# added, then default is 0.0 so that by default it doesn't
# change anything.
#
# Execeptions are MOD_ATK_CRIT_DAMAGE, MOD_SPELL_CRIT_DAMAGE
# which start at 1.5 because by default crits increase
# damage by 50%. MOD_ATK_CRIT_CHANCE and
# MOD_SPELL_CRIT_CHANCE start at 0.01 because by default
# crit chance is 1%.
var _mod_value_map: Dictionary = {
	ModificationType.enm.MOD_ATK_CRIT_CHANCE: Constants.INNATE_MOD_ATK_CRIT_CHANCE,
	ModificationType.enm.MOD_ATK_CRIT_DAMAGE: Constants.INNATE_MOD_ATK_CRIT_DAMAGE,
	ModificationType.enm.MOD_TRIGGER_CHANCES: 1.0,
	ModificationType.enm.MOD_SPELL_DAMAGE_DEALT: 1.0,
	ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED: 1.0,
	ModificationType.enm.MOD_SPELL_CRIT_DAMAGE: Constants.INNATE_MOD_SPELL_CRIT_DAMAGE,
	ModificationType.enm.MOD_SPELL_CRIT_CHANCE: Constants.INNATE_MOD_SPELL_CRIT_CHANCE,
	ModificationType.enm.MOD_BOUNTY_GRANTED: 1.0,
	ModificationType.enm.MOD_BOUNTY_RECEIVED: 1.0,
	ModificationType.enm.MOD_EXP_GRANTED: 1.0,
	ModificationType.enm.MOD_EXP_RECEIVED: 1.0,
	ModificationType.enm.MOD_BUFF_DURATION: 1.0,
	ModificationType.enm.MOD_DEBUFF_DURATION: 1.0,
	ModificationType.enm.MOD_MOVESPEED: 1.0,
	ModificationType.enm.MOD_MOVESPEED_ABSOLUTE: 0.0,
	ModificationType.enm.MOD_MULTICRIT_COUNT: 1.0,
	ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED: 1.0,
	ModificationType.enm.MOD_ATTACKSPEED: 1.0,
	ModificationType.enm.MOD_DPS_ADD: 0.0,

	ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL: 1.0,
	ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL: 1.0,
	ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH: 1.0,
	ModificationType.enm.MOD_ITEM_QUALITY_ON_DEATH: 1.0,

	ModificationType.enm.MOD_ARMOR: 0.0,
	ModificationType.enm.MOD_ARMOR_PERC: 1.0,

	ModificationType.enm.MOD_DAMAGE_BASE: 0.0,
	ModificationType.enm.MOD_DAMAGE_BASE_PERC: 1.0,
	ModificationType.enm.MOD_DAMAGE_ADD: 0.0,
	ModificationType.enm.MOD_DAMAGE_ADD_PERC: 1.0,

	ModificationType.enm.MOD_MANA: 0.0,
	ModificationType.enm.MOD_MANA_PERC: 1.0,
	ModificationType.enm.MOD_MANA_REGEN: 0.0,
	ModificationType.enm.MOD_MANA_REGEN_PERC: 1.0,
	ModificationType.enm.MOD_HP: 0.0,
	ModificationType.enm.MOD_HP_PERC: 1.0,
	ModificationType.enm.MOD_HP_REGEN: 0.0,
	ModificationType.enm.MOD_HP_REGEN_PERC: 1.0,

	ModificationType.enm.MOD_DMG_TO_MASS: 1.0,
	ModificationType.enm.MOD_DMG_TO_NORMAL: 1.0,
	ModificationType.enm.MOD_DMG_TO_CHAMPION: 1.0,
	ModificationType.enm.MOD_DMG_TO_BOSS: 1.0,
	ModificationType.enm.MOD_DMG_TO_AIR: 1.0,

	ModificationType.enm.MOD_DMG_TO_UNDEAD: 1.0,
	ModificationType.enm.MOD_DMG_TO_MAGIC: 1.0,
	ModificationType.enm.MOD_DMG_TO_NATURE: 1.0,
	ModificationType.enm.MOD_DMG_TO_ORC: 1.0,
	ModificationType.enm.MOD_DMG_TO_HUMANOID: 1.0,
	ModificationType.enm.MOD_DMG_TO_CHALLENGE: 1.0,

	ModificationType.enm.MOD_DMG_FROM_ASTRAL: 1.0,
	ModificationType.enm.MOD_DMG_FROM_DARKNESS: 1.0,
	ModificationType.enm.MOD_DMG_FROM_NATURE: 1.0,
	ModificationType.enm.MOD_DMG_FROM_FIRE: 1.0,
	ModificationType.enm.MOD_DMG_FROM_ICE: 1.0,
	ModificationType.enm.MOD_DMG_FROM_STORM: 1.0,
	ModificationType.enm.MOD_DMG_FROM_IRON: 1.0,
}


#########################
###     Built-in      ###
#########################

func _init():
	for mod_type in ModificationType.enm.values():
		if !_mod_value_map.has(mod_type):
			push_error("No default value defined for modification type: ", mod_type)

	for buff_group in range(1, Constants.BUFFGROUP_COUNT + 1):
		_buff_groups[buff_group] = BuffGroupMode.enm.NONE


func _ready():
	if _player == null:
		push_error("Unit was not assigned a player. You must assign a player to unit before adding it to tree, using Unit.set_player().")

	_uid = _uid_max
	_uid_max += 1
	GroupManager.add("units", self, get_uid())

	_target_bitmask = TargetType.make_unit_bitmask(self)

	_selection_indicator = SelectionIndicator.new()
	_selection_indicator.hide()
	_selection_indicator.z_index = -1
	add_child(_selection_indicator)
	
	var regen_timer: ManualTimer = ManualTimer.new()
	regen_timer.one_shot = false
	regen_timer.wait_time = REGEN_PERIOD
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)
	regen_timer.start()

	var builder: Builder = get_player().get_builder()
	builder.apply_effects(self)

#	NOTE: add dummy sprite and selection outline, in case
#	some Unit subclass doesn't set them up. This prevents
#	null access.
	_unit_sprite = Sprite2D.new()
	_unit_sprite_parent = Node2D.new()
	_unit_sprite_parent.add_child(_unit_sprite)
	add_child(_unit_sprite_parent)

	_unit_selection_outline = Sprite2D.new()
	var selection_shader: ShaderMaterial = Preloads.outline_shader.duplicate()
	_unit_selection_outline.set_material(selection_shader)
	_unit_selection_outline_parent = Node2D.new()
	_unit_selection_outline_parent.add_child(_unit_selection_outline)
	add_child(_unit_selection_outline_parent)


#########################
###       Public      ###
#########################

func get_buff_list() -> Array[Buff]:
	return _buff_list


func update(delta: float):
	if is_stunned():
		_total_stun_duration += delta


func set_unit_scale(value: float):
	_unit_sprite_parent.scale = value * Vector2.ONE
	_unit_selection_outline_parent.scale = value * Vector2.ONE


func get_unit_scale() -> float:
	return _unit_sprite_parent.scale.x


func get_uid() -> int:
	return _uid


# NOTE: you must call this instead of queue_free(), so that
# tree_exited() signal is emitted immediately
func remove_from_game():
	var parent: Node = get_parent()

	if parent != null && is_inside_tree():
		parent.remove_child(self)

	queue_free()


func set_player(player: Player):
	_player = player


# Removes the most recent buff. Returns true if there was a
# buff to remove and false otherwise.
# NOTE: unit.purgeBuff() in JASS
func purge_buff(friendly: bool) -> bool:
	var target_buff: Buff = null

	for buff in _buff_list:
		var friendly_match: bool = buff.is_friendly() == friendly

		if buff.is_purgable() && friendly_match:
			target_buff = buff

			break

	if target_buff != null:
		target_buff.purge_buff()

		return true
	else:
		return false


# Triggers REFRESH event for all buffs applied by auras of
# this unit.
# NOTE: Unit.refreshAuras() in JASS
func refresh_auras():
	for aura in _aura_list:
		aura.refresh()


# NOTE: this f-n and add_modified_attack_crit() affect only
# the tower's regular attack. They have no effect on calls
# to do_attack_damage() in tower scripts.
# NOTE: unit.addAttackCrit() in JASS
func add_attack_crit():
	_bonus_crit_count_for_next_attack = _bonus_crit_count_for_next_attack + 1
	_bonus_crit_ratio_for_next_attack += get_prop_atk_crit_damage() - 1.0


# NOTE: unit.addCustomAttackCrit() in JASS
func add_custom_attack_crit(custom_crit_ratio: float):
	_bonus_crit_count_for_next_attack = _bonus_crit_count_for_next_attack + 1
	_bonus_crit_ratio_for_next_attack = custom_crit_ratio


# NOTE: unit.addModifiedAttackCrit() in JASS
func add_modified_attack_crit(crit_damage_add: float, crit_damage_multiply: float):
	_bonus_crit_count_for_next_attack = _bonus_crit_count_for_next_attack + 1
	_bonus_crit_ratio_for_next_attack = (get_prop_atk_crit_damage() - 1.0) * crit_damage_multiply + crit_damage_add


# NOTE: this f-n affects all instances of spell damage,
# including calls to do_spell_damage() in tower scripts.
# NOTE: unit.addSpellCrit() in JASS
func add_spell_crit():
	_bonus_crit_count_for_next_spell += 1


# NOTE: unit.addManaPerc() in JASS
func add_mana_perc(ratio: float):
	var overall_mana: float = get_overall_mana()
	var mana_added: float = ratio * overall_mana
	add_mana(mana_added)


# NOTE: unit.addMana() in JASS
func add_mana(mana_added: float):
	var new_mana: float = _mana + mana_added
	set_mana(new_mana)


func add_autocast(autocast: Autocast):
	autocast.set_caster(self)
	_autocast_list.append(autocast)
	add_child(autocast)


func add_aura(aura_id: int, object_with_buff_var: Object):
	var aura: Aura = Aura.make(aura_id, object_with_buff_var, self)
	_aura_list.append(aura)
	add_child(aura)


# Unaffected by tower exp ratios. Levels up unit if added
# exp pushes the unit past the level up threshold.
# NOTE: unit.addExpFlat() in JASS
func add_exp_flat(amount: float):
	_change_experience(amount)


# Affected by tower exp ratios.
# NOTE: unit.addExp() in JASS
func add_exp(amount_no_bonus: float):
	var received_mod: float = get_prop_exp_received()
	var amount: float = amount_no_bonus * received_mod
	_change_experience(amount)


# Unaffected by tower exp ratios. Returns how much
# experience was actually removed. How much was actually
# removed may be less than requested if the unit has less
# mana than should be removed. In that case unit's mana gets
# set to 0.
# NOTE: unit.removeExpFlat() in JASS
func remove_exp_flat(amount: float) -> float:
	var actual_change: float = _change_experience(-amount)
	var actual_removed: float = abs(actual_change)

	return actual_removed


# Affected by "exp received" modification.
# NOTE: unit.removeExp() in JASS
func remove_exp(amount_no_bonus: float) -> float:
	var received_mod: float = get_prop_exp_received()
	var amount: float = Utils.divide_safe(amount_no_bonus, received_mod)
	var actual_change: float = _change_experience(-amount)
	var actual_removed: float = abs(actual_change)

	return actual_removed


# NOTE: unit.calcChance() in JASS
func calc_chance(chance_base: float) -> bool:
	var mod_trigger_chances: float = get_prop_trigger_chances()
	var chance: float = chance_base * mod_trigger_chances
	var success: bool = Utils.rand_chance(Globals.synced_rng, chance)

	return success


# "Bad" chance is for events that decrease tower's
# perfomance, for example missing attack. Higher value of
# MOD_TRIGGER_CHANCES decreases the chance of bad things
# happening.
# NOTE: unit.calcBadChance() in JASS
func calc_bad_chance(chance: float) -> bool:
	var mod_trigger_chances: float = get_prop_trigger_chances()
	var final_chance: float = Utils.divide_safe(chance, mod_trigger_chances)
	var success: bool = Utils.rand_chance(Globals.synced_rng, final_chance)

	return success


# NOTE: normally spells can't multicrit but if both normal
# crit and extra crit from add_spell_crit() happen at the
# same time, then that's effectively a multicrit.
# NOTE: unit.calcSpellCrit() in JASS
func calc_spell_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_spell_crit_chance() + bonus_chance
	var crit_damage: float = get_spell_crit_damage() + bonus_damage

	var crit_count: int = 0

	var crit_success: bool = Utils.rand_chance(Globals.synced_rng, crit_chance)
	if crit_success:
		crit_count += 1

	crit_count += _bonus_crit_count_for_next_spell
	_bonus_crit_count_for_next_spell = 0

	var crit_ratio: float = 1.0

	for i in range(0, crit_count):
		crit_ratio += crit_damage - 1.0

	return crit_ratio


# NOTE: unit.calcSpellCritNoBonus() in JASS
func calc_spell_crit_no_bonus() -> float:
	var result: float = calc_spell_crit(0.0, 0.0)

	return result


# Returns a randomly calculate crit bonus, no multicrit,
# either crit or not crit.
# NOTE: unit.calcAttackCrit() in JASS
func calc_attack_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(Globals.synced_rng, crit_chance)

	if crit_success:
		return crit_damage
	else:
		return 1.0


# NOTE: unit.calcAttackCritNoBonus() in JASS
func calc_attack_crit_no_bonus() -> float:
	var result: float = calc_attack_crit(0.0, 0.0)

	return result


# Returns a randomly calculated crit bonus (starts at 1.0),
# taking into account multicrit.
# 0 crits, 150% crit damage = 1.0
# 1 crit, 150% crit damage = 1.5
# 3 crits, 150% crit damage = 1.0 + 0.5 + 0.5 + 0.5 = 2.5
# NOTE: unit.calcAttackMulticrit() in JASS
func calc_attack_multicrit(bonus_multicrit: float, bonus_chance: float, bonus_damage: float) -> float:
	var crit_count: int = _generate_crit_count(bonus_multicrit, bonus_chance)
	var crit_damage: float = _calc_attack_multicrit_from_crit_count(crit_count, bonus_damage)

	return crit_damage


# NOTE: no such function in JASS. Added for convenience
# because calc_attack_multicrit(0, 0, 0) is called very
# often.
func calc_attack_multicrit_no_bonus() -> float:
	return calc_attack_multicrit(0, 0, 0)


# NOTE: unit.doSpellDamage() in JASS
func do_spell_damage(target: Unit, damage: float, crit_ratio: float) -> bool:
	var caster: Unit = self
	var dealt_mod: float = caster.get_prop_spell_damage_dealt()
	var received_mod: float = target.get_prop_spell_damage_received()
	var damage_total: float = damage * dealt_mod * received_mod
	var is_main_target: bool = false
	var emit_damage_event: bool = false

	var killed_unit: bool = _do_damage(target, damage_total, crit_ratio, DamageSource.Spell, is_main_target, emit_damage_event)

	return killed_unit


# NOTE: unit.doAttackDamage() in JASS
func do_attack_damage(target: Unit, damage_base: float, crit_ratio: float, crit_count: int = -1, is_main_target: bool = false, emit_damage_event: bool = false):
	var attack_type: AttackType.enm = get_attack_type()
	do_custom_attack_damage(target, damage_base, crit_ratio, attack_type, crit_count, is_main_target, emit_damage_event)


# NOTE: unit.doCustomAttackDamage() in JASS
func do_custom_attack_damage(target: Unit, damage_base: float, crit_ratio: float, attack_type: AttackType.enm, crit_count: int = -1, is_main_target: bool = false, emit_damage_event: bool = false):
	var armor_mod: float = 1.0 - target.get_current_armor_damage_reduction()
	var received_mod: float = target.get_prop_atk_damage_received()

	var damage: float = damage_base * armor_mod * received_mod

	var deals_no_damage_to_immune: bool = AttackType.deals_no_damage_to_immune(attack_type)

	if target.is_immune() && deals_no_damage_to_immune:
		damage = 0

	_do_damage(target, damage, crit_ratio, DamageSource.Attack, is_main_target, emit_damage_event, attack_type, crit_count)


# NOTE: sides_ratio parameter specifies how much less damage
# is dealt to units that are on the "sides" of the aoe
# circle. For example, if sides_ratio is set to 0.3 then
# units on the sides will receive 30% less damage than those
# in the center.
# 
# NOTE: unit.doAttackDamageAoEUnit() in JASS
func do_attack_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var aoe_center: Vector2 = target.get_position_wc3_2d()
	var creep_list: Array = Utils.get_units_in_range(self, TargetType.new(TargetType.CREEPS), aoe_center, radius)

	for creep in creep_list:
		var damage_for_creep: float = Utils.get_aoe_damage(aoe_center, creep, radius, damage, sides_ratio)
		do_attack_damage(creep, damage_for_creep, crit_ratio)


# NOTE: unit.doSpellDamageAoEUnit() in JASS
func do_spell_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	do_spell_damage_aoe(Vector2(target.get_x(), target.get_y()), radius, damage, crit_ratio, sides_ratio)


# NOTE: unit.doSpellDamageAoE() in JASS
func do_spell_damage_aoe(aoe_center: Vector2, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var creep_list: Array = Utils.get_units_in_range(self, TargetType.new(TargetType.CREEPS), aoe_center, radius)

	for creep in creep_list:
		var damage_for_creep: float = Utils.get_aoe_damage(aoe_center, creep, radius, damage, sides_ratio)
		do_spell_damage(creep, damage_for_creep, crit_ratio)


# Deals aoe damage from the position of the unit
# NOTE: unit.doSpellDamagePBAoE() in JASS
func do_spell_damage_pb_aoe(radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	do_spell_damage_aoe(Vector2(get_x(), get_y()), radius, damage, crit_ratio, sides_ratio)


# NOTE: unit.killInstantly() in JASS
func kill_instantly(target: Unit):
	CombatLog.log_ability(self, target, "Instant Kill")
	target._killed_by_unit(self)


# NOTE: unit.modifyProperty() in JASS
func modify_property(mod_type: ModificationType.enm, value: float):
	_modify_property_internal(mod_type, value, 1)


# Adds modifier directly to unit. Modifier will
# automatically scale with this unit's level.
func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, _level, 1)
	_direct_modifier_list.append(modifier)


func remove_modifier(modifier: Modifier):
	if _direct_modifier_list.has(modifier):
		_apply_modifier(modifier, _level, -1)
		_direct_modifier_list.append(modifier)


func change_modifier_level(modifier: Modifier, old_level: int, new_level: int):
	_apply_modifier(modifier, old_level, -1)
	_apply_modifier(modifier, new_level, 1)


func add_silence():
	_silence_count += 1


func remove_silence():
	_silence_count -= 1


func add_stun():
	var stun_started: bool = _stun_count == 0

	_stun_count += 1

	if stun_started:
		_stun_effect_id = Effect.create_simple_at_unit_attached("res://src/effects/stun_visual.tscn", self, Unit.BodyPart.OVERHEAD)
		Effect.set_auto_destroy_enabled(_stun_effect_id, false)


func remove_stun():
	_stun_count -= 1

	var stun_ended: bool = _stun_count == 0
	
	if stun_ended:
		Effect.destroy_effect(_stun_effect_id)
		_stun_effect_id = -1


func add_ethereal():
	_ethereal_count += 1


func remove_ethereal():
	_ethereal_count -= 1


# Returns the amount of mana that was actually subtracted.
# NOTE: unit.subtractMana() in JASS
func subtract_mana(amount: float, subtract_if_not_enough: bool) -> float:
	var enough_mana: bool = _mana >= amount 

	if enough_mana:
		var new_mana: float = clampf(_mana - amount, 0.0, _mana)
		set_mana(new_mana)

		return amount
	else:
		if subtract_if_not_enough:
			set_mana(0)
		else:
			return 0
	
	return 0


func get_selection_outline() -> Node2D:
	return _unit_selection_outline


#########################
###      Private      ###
#########################

func _setup_selection_signals(selection_area: Area2D):
	selection_area.mouse_entered.connect(_on_selection_area_mouse_entered)
	selection_area.mouse_exited.connect(_on_selection_area_mouse_exited)


func _on_selection_area_mouse_entered():
	EventBus.mouse_entered_unit.emit(self)


func _on_selection_area_mouse_exited():
	EventBus.mouse_exited_unit.emit(self)


func _modify_property_internal(mod_type: ModificationType.enm, value: float, direction: int):
	var health_ratio: float = get_health_ratio()
	var mana_ratio: float = get_mana_ratio()

	var current_value: float = _mod_value_map[mod_type]
	var new_value: float = current_value + direction * value
	_mod_value_map[mod_type] = new_value

#	NOTE: restore original health and mana ratios. For
#	example, if original mana was 50/100 and mana was
#	increased by 50, then final values will be 75/150 to
#	preserve the 50% ratio.
	var new_health_max: float = get_overall_health()
	_health = health_ratio * new_health_max
	var new_mana_max: float = get_overall_mana()
	_mana = mana_ratio * new_mana_max


# Changes experience of unit. Change can be positive or
# negative. Level will also be changed accordingly. Note
# that level downs are possible.
func _change_experience(amount: float) -> float:
	var old_exp: float = _experience
	var new_exp: float = max(0.0, _experience + amount)
	var actual_change = new_exp - old_exp
	var old_level: int = _level
	var new_level: int = Experience.get_level_at_exp(new_exp)

	_experience = new_exp

	var level_has_changed: bool = new_level != old_level
	var level_increased: bool = new_level > old_level
	
	if level_has_changed:
		set_level(new_level)
		
#		NOTE: it is important to emit level_changed() signal
#		multiple times if level has changed by more than 1.
#		Some tower logic depend on this behavior.
		var level_change_amount: int = absi(new_level - old_level)
		for i in range(0, level_change_amount):
			level_changed.emit(level_increased)
		
		EventBus.unit_leveled_up.emit()

	var sign_string: String
	if amount >= 0:
		sign_string = "+"
	else:
		sign_string = "-"
	var number_string: String = String.num(abs(amount), 1)
	var exp_text: String = "%s%s exp" % [sign_string, number_string]
	var text_color: Color
	if amount >= 0:
		text_color = Color.LIME_GREEN
	else:
		text_color = Color.RED

	get_player().display_floating_text(exp_text, self, text_color)

	if level_increased:
		var effect_id: int = Effect.create_simple_at_unit("res://src/effects/level_up.tscn", self)
		var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.LEVEL_UP_EFFECT_SIZE
		Effect.set_scale(effect_id, effect_scale)
		var stomp_effect: int = Effect.create_simple_at_unit("res://src/effects/warstomp_caster.tscn", self, Unit.BodyPart.ORIGIN)
		Effect.set_z_index(stomp_effect, Effect.Z_INDEX_BELOW_TOWERS)
		Effect.set_color(stomp_effect, Color.BROWN)

		var level_up_text: String = "Level %d" % _level
		get_player().display_floating_text(level_up_text, self, Color.GOLD)

		SFX.sfx_at_unit(SfxPaths.LEVEL_UP, self)

	CombatLog.log_experience(self, amount)

	return actual_change


func _add_floating_text_for_damage(damage: float, crit_count: int, damage_source: DamageSource, is_main_target: bool, target: Unit):
	var damage_color: Color
	var damage_text: String = str(floori(damage))

#	NOTE: do not show crits for 0 damage, because it shows
#	up as "0!" and looks weird. Do show "0" for spell damage
#	because it indicates helpful info about certain
#	abilities.
	if crit_count > 0 && roundi(damage) == 0:
		return
	
	match damage_source:
		DamageSource.Attack: 
			damage_color = Color.RED
		DamageSource.Spell:
			damage_color = Color.SKY_BLUE
	
	var is_critical: bool = crit_count > 0

	for i in range(0, crit_count):
		damage_text += "!"

	var text_origin_unit: Unit
	if is_critical && damage_source == DamageSource.Attack:
		text_origin_unit = self
	else:
		text_origin_unit = target

#	NOTE: confusing logic for this boolean but this is how
#	it worked in original youtd
	var show_all_damage_numbers: bool = Settings.get_bool_setting(Settings.SHOW_ALL_DAMAGE_NUMBERS)
	var floating_text_should_be_shown: bool = show_all_damage_numbers || (damage_source == DamageSource.Attack && is_critical && is_main_target) || (damage_source == DamageSource.Spell && is_critical)
	if !floating_text_should_be_shown:
		return
	
	get_player().display_floating_text_x_2(damage_text, text_origin_unit, damage_color, 0, 0, 1.0, 0, 50)


# Example:
# If crits deal 125% of normal damage and crit ratio is 1.50
# Then crit count = (1.50 - 1.0) / (1.25 - 1.0) = 0.50 / 0.25 = 2
func _derive_crit_count_from_crit_ratio(crit_ratio: float, damage_source: DamageSource) -> int:
	var crit_damage_mod: float
	match damage_source:
		DamageSource.Attack:
			crit_damage_mod	= get_prop_atk_crit_damage()
		DamageSource.Spell:
			crit_damage_mod	= get_spell_crit_damage()

	var crit_count: int = roundi(Utils.divide_safe((crit_ratio - 1.0), (crit_damage_mod - 1.0)))

	return crit_count


# Generates a random crit count for attack damage
func _generate_crit_count(bonus_multicrit: float, bonus_chance: float) -> int:
	var multicrit_count_max: int = get_prop_multicrit_count() + int(bonus_multicrit)
	var current_crit_chance: float = get_prop_atk_crit_chance() + bonus_chance

	var crit_count: int = 0
	
	for _i in range(multicrit_count_max):
		var capped_crit_chance: float = min(current_crit_chance, Constants.ATK_CRIT_CHANCE_CAP)
		var is_critical: bool = Utils.rand_chance(Globals.synced_rng, capped_crit_chance)

		if is_critical:
			crit_count += 1

#			Decrease chance of each subsequent multicrit to
#			implement diminishing returns.
			current_crit_chance *= Constants.ATK_MULTICRIT_DIMISHING
		else:
			break

	return crit_count


# Same as calc_attack_multicrit(), but accepts an already
# calculated crit count. Used by Tower.
func _calc_attack_multicrit_from_crit_count(crit_count: int, bonus_damage: float) -> float:
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

# 	NOTE: subtract 1.0 from crit_damage, so we do
#	1.0 + 0.5 + 0.5 + 0.5...
# 	not
#	1.0 + 1.5 + 1.5 + 1.5...
	var total_crit_damage: float = 1.0 + (crit_damage - 1.0) * crit_count

	total_crit_damage = max(0.0, total_crit_damage)

	return total_crit_damage


func _do_damage(target: Unit, damage_base: float, crit_ratio: float, damage_source: DamageSource, is_main_target: bool, emit_damage_event: bool = false, attack_type: AttackType.enm = get_attack_type(), crit_count: int = -1) -> bool:
	if !target is Creep:
		push_error("Attempted to deal damage to a unit which is not a creep: %s. Can deal damage only to creeps." % target)

		return false

#	NOTE: if crit_count is -1, then _do_damage() was called
#	from f-n like do_attack_damage(), where we only have
#	access to crit_ratio. In that case derive crit count
#	from crit ratio. The only case where we have access to
#	crit_ratio is for regular tower attacks.
	if crit_count == -1:
		crit_count = _derive_crit_count_from_crit_ratio(crit_ratio, damage_source)

	var target_size: CreepSize.enm = target.get_size()
	var size_mod: float = get_damage_to_size(target_size)
	var creep_category: CreepCategory.enm = target.get_category()
	var category_mod: float = get_damage_to_category(creep_category)
	var armor_type: ArmorType.enm = target.get_armor_type()
	var armor_type_mod: float = AttackType.get_damage_against(attack_type, armor_type)
	var spell_damage_multiplier: float = ArmorType.get_spell_damage_taken(armor_type)

	var damage: float = damage_base * size_mod * category_mod
	
	if self is Tower:
		var tower: Tower = self as Tower
		var element: Element.enm = tower.get_element()
		var element_mod: float = target.get_damage_from_element(element)
		damage *= element_mod

	match damage_source:
		DamageSource.Attack: damage *= armor_type_mod
		DamageSource.Spell: damage *= spell_damage_multiplier

# 	Immune creeps take 0 damage from spells
	if damage_source == DamageSource.Spell && target.is_immune():
		damage = 0

	var damage_before_damage_event: float = damage

#	NOTE: emit_damage_event arg is true only for tower
#	attacks, false for all other calls to this function
	if emit_damage_event:
		var damage_event: Event = Event.new(target)
		damage_event.damage = damage
		damage_event._is_main_target = is_main_target
		damage_event._number_of_crits = crit_count
		dealt_damage.emit(damage_event)
# 		NOTE: update damage value because it could've been
# 		altered by DAMAGE callbacks
		damage = damage_event.damage

#	NOTE: crit damage bonus must be applied after "damage"
#	event. This is according to this comment in the original
#	script for Burrow tower.
#	Comment: "The engine calculates critical strike extra
#	damage ***AFTER*** the onDamage event, so there is no
#	need to care about it in this trigger."
	damage *= crit_ratio

	var damage_before_damaged_event: float = damage

	var attacker: Unit = self

	if attacker is Tower:
		var damaged_event: Event = Event.new(attacker)
		damaged_event.damage = damage
		damaged_event._is_main_target = is_main_target
		damaged_event._is_spell_damage = damage_source == DamageSource.Spell
		damaged_event._number_of_crits = crit_count
		target.damaged.emit(damaged_event)

# 		NOTE: update damage value because it could've been
# 		altered by event handlers of target's "damaged" event
		damage = damaged_event.damage

	var damage_is_in_bounds: bool = Constants.DAMAGE_MIN <= damage && damage <= Constants.DAMAGE_MAX

	if !damage_is_in_bounds:
		push_error("Damage out of bounds. Damage base = %f, damage before DAMAGE event = %f, damage before DAMAGED event = %f, damage final = %f" % [damage_base, damage_before_damage_event, damage_before_damaged_event, damage])

		if attacker is Tower:
			push_error("Tower id = %d" % attacker.get_id())

		damage = clampf(damage, Constants.DAMAGE_MIN, Constants.DAMAGE_MAX)
	
	_damage_dealt_total += damage
	
	var wave_level: int = target.get_spawn_level()
	
	if !_damage_dealt_to_wave_map.has(wave_level):
		_damage_dealt_to_wave_map[wave_level] = 0
	
	_damage_dealt_to_wave_map[wave_level] += damage

	if damage > _best_hit:
		_best_hit = damage

	var health_before_damage: float = target.get_health()
	target.set_health(health_before_damage - damage)

	CombatLog.log_damage(self, target, damage_source, damage, crit_count)

	get_player().add_to_total_damage(damage)

	_add_floating_text_for_damage(damage, crit_count, damage_source, is_main_target, target)

	var health_after_damage: float = target.get_health()
	var damage_killed_unit: bool = health_before_damage > 0 && health_after_damage <= 0

	if damage_killed_unit:
		target._killed_by_unit(self)

	return damage_killed_unit


# Called when unit killed by caster unit
func _killed_by_unit(caster: Unit):
	var death_event: Event = Event.new(caster)
	death.emit(death_event)

	if caster != null:
		caster._accept_kill(self)

	var caster_item_chance: float = caster.get_item_drop_ratio()
	var target_item_chance: float = get_item_drop_ratio_on_death()
	var item_chance: float = Constants.BASE_ITEM_DROP_CHANCE * caster_item_chance * target_item_chance

	var creep: Creep = self as Creep

	if creep != null:
		var creep_size: CreepSize.enm = creep.get_size_including_challenge_sizes()
		var item_drop_roll_count: int = CreepSize.get_item_drop_roll_count(creep_size)
		
		if Config.always_drop_items():
			item_drop_roll_count = 1
			item_chance = 1.0
		
		for i in range(0, item_drop_roll_count):
			var item_dropped: bool = Utils.rand_chance(Globals.synced_rng, item_chance)

			if item_dropped:
				creep.drop_item(caster, true)

	remove_from_game()


# Called when unit kills target unit
func _accept_kill(target: Unit):
	CombatLog.log_kill(self, target)
	
	var experience_gained: float = _get_experience_for_target(target)
	_change_experience(experience_gained)

	var target_owner: Player = target.get_player()

	var bounty_gained: int = _get_bounty_for_target(target)
	if bounty_gained > 0:
		target_owner.give_gold(bounty_gained, target, false, true)

	_kill_count += 1

	var kill_event: Event = Event.new(target)
	kill.emit(kill_event)


# This is for internal use in buff.gd only. For external
# use, call BuffType.apply().
func _add_buff_internal(buff: Buff):
	var buff_type_name: String = buff.get_buff_type_name()
	_buff_map[buff_type_name] = buff

	_buff_list.append(buff)
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_level(), 1)
	
	buff_list_changed.emit()


func _apply_modifier(modifier: Modifier, level: int, modify_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var value: float = modification.value_base + modification.level_add * level

		_modify_property_internal(modification.type, value, modify_direction)


func _remove_buff_internal(buff: Buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_level(), -1)

	var buff_type_name: String = buff.get_buff_type_name()
	_buff_map.erase(buff_type_name)

	_buff_list.erase(buff)
	buff_list_changed.emit()


# Set node which will be used to determine the visual
# position of the unit.
func _set_visual_node(visual_node: Node2D):
	_visual_node = visual_node
	_visual_node.position.y = -_position_wc3.z


# Save the sprite node. Also create a duplicate outline
# sprite base on the original sprite.
# NOTE: sprite is Sprite2D in case of tower and
# AnimatedSprite2D in case of Creeps. The operations we do
# here are valid for both types.
# NOTE: sprite parent node is used to chance scale and color of the sprite without affecting default values.
func _setup_unit_sprite(sprite_node: Node2D, sprite_parent_node: Node2D, outline_thickness: float):
#	NOTE: delete existing sprite node and selection outline
	if _unit_sprite_parent != null:
		_unit_sprite_parent.queue_free()
	if _unit_selection_outline_parent != null:
		_unit_selection_outline_parent.queue_free()
	
	_unit_sprite = sprite_node
	_unit_sprite_parent = sprite_parent_node

#	NOTE: create a duplicate sprite to use it as selection
#	outline. Outline is implemented by using a shader which
#	draws an outline around the sprite and erases the
#	original sprite.
# 	NOTE: also duplicate the shader so that shader
# 	parameters are individual to scenes.
	var sprite_for_outline = sprite_node.duplicate()
	var selection_shader: ShaderMaterial = Preloads.outline_shader.duplicate()
	sprite_for_outline.set_material(selection_shader)
	sprite_for_outline.get_material().set_shader_parameter("line_thickness", outline_thickness)

#	NOTE: set z_index of outline so that it's drawn above
#	all other units
	sprite_for_outline.z_index = 1

#	NOTE: need to keep sprite and outline under separate
#	parents because outline should not be affected by
#	changes to sprite color, which is done via sprite parent
	_unit_selection_outline_parent = Node2D.new()
	_unit_sprite_parent.add_sibling(_unit_selection_outline_parent)

	_unit_selection_outline_parent.add_child(sprite_for_outline)
	_unit_selection_outline = sprite_for_outline

#	NOTE: initially hide the outline, it will get shown when
#	unit is hovered or selected.
	_unit_selection_outline.hide()


# Call this in subclass to set dimensions of unit. Use
# Utils.get_sprite_dimensions() or
# Utils.get_animated_sprite_dimensions() to get the
# dimensions of the sprite in subclass. This will be used to
# calculate positions of different body parts of the unit.
func _set_unit_dimensions(sprite_dimensions: Vector2):
	_sprite_dimensions = sprite_dimensions


# Sets size(radius) of selection circle.
# Should be called in subclasses.
func _set_selection_size(selection_size: float):
	_selection_indicator.visual_size = selection_size


func _get_bounty_for_target(target: Unit) -> int:
	if !target is Creep:
		return 0

	var tower: Unit = self
	var creep: Creep = target as Creep
	var bounty_base: float = creep.get_base_bounty_value()
	var granted_mod: float = creep.get_prop_bounty_granted()
	var received_mod: float = tower.get_prop_bounty_received()
	var bounty: int = floori(bounty_base * granted_mod * received_mod)

	return bounty


func _get_experience_for_target(target: Unit) -> float:
	if !target is Creep:
		return 0

	var tower: Unit = self
	var creep: Creep = target as Creep
	var creep_size: CreepSize.enm = creep.get_size_including_challenge_sizes()
	var experience_base: float = CreepSize.get_experience(creep_size)
	var granted_mod: float = creep.get_prop_exp_granted()
	var received_mod: float = tower.get_prop_exp_received()
	var experience: float = experience_base * granted_mod * received_mod

	return experience


# Returns a prop value after applying diminishing returns to
# it. Diminishing returns reduce effectiveness of mods as
# the prop value gets further away from [0.6, 1.7] range.
func _get_prop_with_diminishing_returns(type: ModificationType.enm) -> float:
	var value: float = max(0, _mod_value_map[type])

	if value > 1.7:
		return 1.7 + (value - 1.7) / pow(1.0 + value - 1.7, 0.66)
	elif value < 0.6:
		return 0.6 / pow(1.0 + 0.6 - value, 1.6)
	else:
		return value


#########################
###     Callbacks     ###
#########################

func _on_regen_timer_timeout():
	var mana_regen: float = get_overall_mana_regen()
	set_mana(_mana + mana_regen)

	var health_regen: float = get_overall_health_regen()
	set_health(_health + health_regen)


#########################
### Setters / Getters ###
#########################

func get_target_bitmask() -> int:
	return _target_bitmask


# Returns name used in the combat log
func get_log_name():
	var instance_id: int = get_instance_id()
	var log_name: String = "Unit-%d" % instance_id

	return log_name


func get_aura_list() -> Array[Aura]:
	return _aura_list


func get_autocast_list() -> Array[Autocast]:
	return _autocast_list


# NOTE: for now just returning the one single player
# instance since multiplayer isn't implemented. Also, the
# name isn't "get_player()" because that is already a
# function of Node class.
# 
# NOTE: unit.getOwner() in JASS
# Node.get_owner() is a built-in godot f-n
func get_player() -> Player:
	return _player


func belongs_to_local_player() -> bool:
	var result: bool = _player == PlayerManager.get_local_player()
	
	return result


# NOTE: this is a stub, used in original tower scripts but
# not needed in godot engine.
# NOTE: unit.setAnimationByIndex() in JASS
func set_animation_by_index(_unit: Unit, _index: int):
	pass


# Sets sprite's base color. Sprite will have this color
# forever and it will be mixed with the color passed to
# set_sprite_color(). This is intended to be called once
# when creeps are created to apply color based on wave
# specials.
func set_sprite_base_color(color: Color):
	_unit_sprite.modulate = color


# Changes color of sprite. Note that this color will be
# mixed with base color - it does not overwrite it. Pass
# Color.WHITE to reset to base color.
# NOTE: not modifying color of selection outline here because outline should not be affected by sprite color
# NOTE: SetUnitVertexColor() in JASS
func set_sprite_color(value: Color):
	_unit_sprite_parent.modulate = value


# NOTE: overriden in Tower to return non-null value
func get_current_target() -> Unit:
	return null


# NOTE: unit.isImmune() in JASS
func is_immune() -> bool:
	return _immune


func set_immune(immune: bool):
	_immune = immune


func set_level(new_level: int):
	var old_level: int = _level
	_level = new_level

#	NOTE: apply level change to modifiers
	for modifier in _direct_modifier_list:
		change_modifier_level(modifier, old_level, new_level)


# NOTE: Node2D.position and Node2D.get_position() return
# position of node on the canvas, which is not the same as
# the 3d position! Use get_position_canvas() instead of
# get_position() to make the difference explicity.
func get_position_canvas() -> Vector2:
	return position


func get_visual_position() -> Vector2:
	return _visual_node.global_position


func get_position_wc3_2d() -> Vector2:
	var position_2d: Vector2 = Vector2(_position_wc3.x, _position_wc3.y)

	return position_2d


func get_position_wc3() -> Vector3:
	return _position_wc3


func set_position_wc3(value: Vector3):
	_position_wc3 = value

	position.x = Utils.to_pixels(_position_wc3.x)
	position.y = Utils.to_pixels(_position_wc3.y / 2)

#	NOTE: it would be more correct to convert z to pixels
#	and then multiply by some constant based on isometric
#	perspective. By luck, it works by using z without
#	conversion.
	if _visual_node != null:
		_visual_node.position.y = -_position_wc3.z


func set_position_wc3_2d(value: Vector2):
	set_position_wc3(Vector3(value.x, value.y, get_z()))


func set_z(z: float):
	var new_position_wc3: Vector3 = Vector3(_position_wc3.x, _position_wc3.y, z)
	set_position_wc3(new_position_wc3)


# Returns approximate position of the body part of unit on
# the canvas coordinate space (not 3d wc3).
# NOTE: body parts were used in original API based on
# coordinates of body parts of 3D models. Approximate this
# feature for 2d tiles by defining body part positions as:
# ORIGIN = bottom of sprite
# CHEST = middle of sprite
# HEAD = top of sprite
# Note that "sprite" here means the occupied part of the
# texture. Some sprites occupy only a small portion of the
# total texture so using texture center/dimensions would
# cause incorrect results.
func get_body_part_position(body_part: Unit.BodyPart) -> Vector3:
	var origin_pos: Vector3 = get_position_wc3()
	
	if _visual_node == null:
		print_debug("No visual node defined")

		return origin_pos

	var body_part_offset_canvas: Vector2 = get_body_part_offset(body_part)
	var body_part_offset_z: float = -body_part_offset_canvas.y
	var body_part_position: Vector3 = origin_pos + Vector3(0, 0, body_part_offset_z)

	return body_part_position


# NOTE: returns position in canvas coords
func get_body_part_offset(body_part: Unit.BodyPart) -> Vector2:
	var sprite_height: float = float(_sprite_dimensions.y)

	match body_part:
		BodyPart.OVERHEAD: return Vector2(0, -sprite_height * 1.0)
		BodyPart.HEAD: return Vector2(0, -sprite_height * 0.75)
		BodyPart.CHEST: return Vector2(0, -sprite_height * 0.5)
		BodyPart.ORIGIN: return Vector2.ZERO
	
	return Vector2.ZERO


# NOTE: unit.getX() in JASS
func get_x() -> float:
	return _position_wc3.x


# NOTE: unit.getY() in JASS
func get_y() -> float:
	return _position_wc3.y


# NOTE: unit.getZ() in JASS
func get_z() -> float:
	return _position_wc3.z


func get_visual_node() -> Node2D:
	return _visual_node


# NOTE: "getProp_BuffDuration()" in JASS
func get_prop_buff_duration() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_BUFF_DURATION)

# NOTE: "getProp_DebuffDuration()" in JASS
func get_prop_debuff_duration() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_DEBUFF_DURATION)

# NOTE: "getProp_AtkCritChance()" in JASS
func get_prop_atk_crit_chance() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_ATK_CRIT_CHANCE])

# NOTE: "getProp_AtkCritDamage()" in JASS
func get_prop_atk_crit_damage() -> float:
	return max(1.0, _mod_value_map[ModificationType.enm.MOD_ATK_CRIT_DAMAGE])

# NOTE: "getProp_BountyReceived()" in JASS
func get_prop_bounty_received() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_BOUNTY_RECEIVED)

# NOTE: "getProp_BountyGranted()" in JASS
func get_prop_bounty_granted() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_BOUNTY_GRANTED])

# NOTE: "getProp_ExpReceived()" in JASS
func get_prop_exp_received() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_EXP_RECEIVED)

# NOTE: "getProp_ExpGranted()" in JASS
func get_prop_exp_granted() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_EXP_GRANTED])

func get_damage_to_air() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_AIR])

func get_damage_to_boss() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_BOSS])

func get_damage_to_mass() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_MASS])

func get_damage_to_normal() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_NORMAL])

func get_damage_to_champion() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_CHAMPION])

func get_damage_to_undead() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_UNDEAD])

func get_damage_to_humanoid() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_HUMANOID])

func get_damage_to_challenge() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_CHALLENGE])

func get_damage_to_nature() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_NATURE])

func get_damage_to_magic() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_MAGIC])

func get_damage_to_orc() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DMG_TO_ORC])

func get_item_drop_ratio() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_ITEM_CHANCE_ON_KILL)

func get_item_quality_ratio() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_ITEM_QUALITY_ON_KILL)

func get_item_drop_ratio_on_death() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_ITEM_CHANCE_ON_DEATH])

func get_item_quality_ratio_on_death() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_ITEM_QUALITY_ON_DEATH])

# NOTE: "getProp_TriggerChances()" in JASS
func get_prop_trigger_chances() -> float:
	return _get_prop_with_diminishing_returns(ModificationType.enm.MOD_TRIGGER_CHANCES)

func get_prop_multicrit_count() -> int:
	return int(max(0, _mod_value_map[ModificationType.enm.MOD_MULTICRIT_COUNT]))

# NOTE: "getProp_SpellDmgDealt()" in JASS
func get_prop_spell_damage_dealt() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_SPELL_DAMAGE_DEALT])

# NOTE: "getProp_SpellDmgReceived()" in JASS
func get_prop_spell_damage_received() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_SPELL_DAMAGE_RECEIVED])

# NOTE: "getProp_SpellCritChance()" in JASS
func get_spell_crit_chance() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_SPELL_CRIT_CHANCE])

# NOTE: "getProp_SpellCritDamage()" in JASS
func get_spell_crit_damage() -> float:
	return max(1.0, _mod_value_map[ModificationType.enm.MOD_SPELL_CRIT_DAMAGE])


# NOTE: [ORIGINAL_GAME_DEVIATION] in original game,
# attack speed mod is not clamped when displayed, only when
# used. So if attack speed is -50% it would show as "-50%"
# in tower details but would actually by clamped to the min
# value (20%).
# 
# Changed it so that both displayed and actually used values
# are clamped.
# 
# NOTE: in original youtd, this f-n returns a value which
# starts from 0%. In youtd2, this f-n returns a value which
# starts from 100%. Keep this in mind when
# translating/comparing original JASS tower scripts.
# 
# NOTE: "getProp_Attackspeed()" in JASS
func get_attack_speed_modifier() -> float:
	var attack_speed_mod: float = _mod_value_map[ModificationType.enm.MOD_ATTACKSPEED]
	attack_speed_mod = clampf(attack_speed_mod, Constants.MOD_ATTACKSPEED_MIN, Constants.MOD_ATTACKSPEED_MAX)

	return attack_speed_mod


func get_level() -> int:
	return _level

func is_silenced() -> bool:
	return _silence_count > 0

func is_stunned() -> bool:
	return _stun_count > 0

# Returns the total amount of time that this unit was
# stunned for during it's lifetime.
func get_total_stun_duration() -> float:
	return _total_stun_duration

# NOTE: unit.isBanished() in JASS
func is_ethereal() -> bool:
	return _ethereal_count > 0

# NOTE: overriden in Tower and Creep subclasses
func is_in_combat() -> bool:
	return false

# NOTE: unit.getBuffOfType() in JASS
func get_buff_of_type(buff_type: BuffType) -> Buff:
	var buff_type_name: String = buff_type.get_unique_name()
	var buff: Buff = _buff_map.get(buff_type_name, null)

	return buff


# NOTE: this f-n is not implemented, see comment for
# BuffType.set_stacking_group() for reason.
# 
# NOTE: unit.getBuffOfGroup() in JASS
# func get_buff_of_group(stacking_group: String) -> Buff:
#	return null


# NOTE: analog of SetUnitState(unit, UNIT_STATE_MANA) in JASS
func set_mana(new_mana: float):
	var overall_mana: float = get_overall_mana()
	_mana = clampf(new_mana, 0.0, overall_mana)
	mana_changed.emit()


func set_base_mana(base_mana: float):
	_base_mana = base_mana


func get_base_mana() -> float:
	return _base_mana

func get_base_mana_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_MANA]

func get_base_mana_bonus_percent() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_MANA_PERC])

# NOTE: "GetUnitState(unit, UNIT_STATE_MAX_MANA)" in JASS
func get_overall_mana() -> float:
	return max(0, (get_base_mana() + get_base_mana_bonus()) * get_base_mana_bonus_percent())

# Returns current percentage of mana
func get_mana_ratio() -> float:
	var overall_mana: float = get_overall_mana()
	var ratio: float = Utils.divide_safe(_mana, overall_mana)

	return ratio


func set_base_mana_regen(base_mana_regen: float):
	_base_mana_regen = base_mana_regen

func get_base_mana_regen() -> float:
	return _base_mana_regen

# NOTE: "getProp_ManaRegBonus()" in JASS
func get_base_mana_regen_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_MANA_REGEN]

# NOTE: "getProp_ManaRegPercBonus()" in JASS
func get_base_mana_regen_bonus_percent() -> float:
	return _mod_value_map[ModificationType.enm.MOD_MANA_REGEN_PERC]

# NOTE: regen values can be negative - this is on purpose.
# If regen is negative, then unit will start losing mana.
# This is how it works in original game.
func get_overall_mana_regen() -> float:
	return (get_base_mana_regen() + get_base_mana_regen_bonus()) * get_base_mana_regen_bonus_percent()


# Returns damage done, in percentage.
# Example: current health = 30/100 => damage done = 0.7 (70%)
func get_damage_done() -> float:
	var overall_health: float = get_overall_health()
	var lowest_health_ratio: float = Utils.divide_safe(_lowest_health, overall_health)
	var damage_done: float = 1.0 - lowest_health_ratio
	
	return damage_done


# NOTE: analog of SetUnitState(unit, UNIT_STATE_LIFE) in JASS
func set_health(new_health: float):
	var overall_health: float = get_overall_health()
	_health = clampf(new_health, 0.0, overall_health)
	if _health < _lowest_health:
		_lowest_health = _health
	health_changed.emit()


# NOTE: need this function for "Second Chance" special where
# creep health needs to be set over max health.
func set_health_over_max(new_health: float):
	_health = max(new_health, 0.0)
	health_changed.emit()


# NOTE: analog of GetUnitState(unit, UNIT_STATE_LIFE) in JASS
func get_health() -> float:
	return _health

func get_base_health() -> float:
	return _base_health

func set_base_health(value: float):
	_base_health = value
	_lowest_health = value

func get_base_health_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_HP]

func get_base_health_bonus_percent() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_HP_PERC])

# NOTE: do not allow max hp to go below 1 because that
# doesn't make sense and the combat system won't work
# correctly if a unit has max hp of 0
# NOTE: analog of GetUnitState(unit, UNIT_STATE_MAX_LIFE) in JASS
func get_overall_health() -> float:
	return max(1, (get_base_health() + get_base_health_bonus()) * get_base_health_bonus_percent())

# Returns current percentage of health
# NOTE: unit.getLifePercent() in JASS
func get_health_ratio() -> float:
	var overall_health: float = get_overall_health()
	var ratio: float = Utils.divide_safe(_health, overall_health)

	return ratio

func get_base_health_regen() -> float:
	return _base_health_regen

func get_base_health_regen_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_HP_REGEN]

func get_base_health_regen_bonus_percent() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_HP_REGEN_PERC])

# NOTE: regen values can be negative - this is on purpose.
# If regen is negative, then unit will start losing health.
# This is how it works in original game.
func get_overall_health_regen() -> float:
	return (get_base_health_regen() + get_base_health_regen_bonus()) * get_base_health_regen_bonus_percent()

func get_prop_move_speed() -> float:
	var base_value: float = _mod_value_map[ModificationType.enm.MOD_MOVESPEED]
	var value: float

	if base_value > 1.0:
		value = base_value
	else:
		value = pow(3.0, base_value - 1.0)

	return value


func get_prop_move_speed_absolute() -> float:
	return _mod_value_map[ModificationType.enm.MOD_MOVESPEED_ABSOLUTE]

func get_base_movespeed() -> float:
	return Constants.DEFAULT_MOVE_SPEED

func get_prop_atk_damage_received() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_ATK_DAMAGE_RECEIVED])

func get_display_name() -> String:
	return "Generic Unit"


func set_hovered(hovered: bool):
	if _selected:
		return

	var indicator_color: Color
	if belongs_to_local_player():
		indicator_color = Color.WHITE
	else:
		indicator_color = Color.YELLOW

	_selection_indicator.modulate = indicator_color
	_unit_selection_outline.material.set_shader_parameter("line_color", indicator_color)
	_selection_indicator.set_visible(hovered)
	_unit_selection_outline.set_visible(hovered)
	_hovered = hovered
	hovered_changed.emit()


func is_selected() -> bool:
	return _selected


func is_hovered() -> bool:
	return _hovered


# NOTE: this function only changes the visual state of this
# unit - it doesn't make it THE selected unit. SelectUnit
# does that.
func set_selected(selected_arg: bool):
	var selection_color: Color
	if self is Creep:
		selection_color = Color.RED
	else:
		if belongs_to_local_player():
			selection_color = Color.GREEN
		else:
			selection_color = Color.ORANGE

	_selection_indicator.modulate = selection_color
	_selection_indicator.set_visible(selected_arg)
	_unit_selection_outline.material.set_shader_parameter("line_color", selection_color)
	_unit_selection_outline.set_visible(selected_arg)
	_selected = selected_arg
	selected_changed.emit()

func get_base_damage_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_DAMAGE_BASE]

func get_base_damage_bonus_percent() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DAMAGE_BASE_PERC])

func get_damage_add() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DAMAGE_ADD])

func get_damage_add_percent() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_DAMAGE_ADD_PERC])

func get_current_armor_damage_reduction() -> float:
	var armor: float = get_overall_armor()

	var reduction: float
	if armor >= 0:
		reduction = armor / (armor + 25)
	else:
		reduction = 0.0
#		NOTE: JASS code has the formula below, not sure why.
#		This would mean that if armor is reduced below 0
#		then reduction would be negative - meaning that
#		creep would get healed??? Probably somewhere else in
#		JASS code this value would be forced to 0 anyway.
		# reduction = pow(0.94, -armor) - 1.0

	return reduction

# NOTE: analog of GetUnitState(unit, UNIT_STATE_MANA) in JASS
func get_mana() -> float:
	return _mana

func set_base_armor(value: float):
	_base_armor = value

func get_base_armor() -> float:
	return _base_armor

func get_base_armor_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_ARMOR]

func get_base_armor_bonus_percent() -> float:
	return max(0, _mod_value_map[ModificationType.enm.MOD_ARMOR_PERC])

func get_overall_armor() -> float:
	return max(0, (get_base_armor() + get_base_armor_bonus()) * get_base_armor_bonus_percent())

func get_overall_armor_bonus() -> float:
	return (get_base_armor() + get_base_armor_bonus()) * get_base_armor_bonus_percent() - get_base_armor()

func get_dps_bonus() -> float:
	return _mod_value_map[ModificationType.enm.MOD_DPS_ADD]


func get_damage_from_element(element: Element.enm) -> float:
	var mod_type: ModificationType.enm = Element.convert_to_dmg_from_element_mod(element)
	var damage_mod: float = max(0, _mod_value_map[mod_type])

	return damage_mod


# NOTE: unit.getDamageToCategory() in JASS
func get_damage_to_category(category: CreepCategory.enm) -> float:
	var mod_type: ModificationType.enm = CreepCategory.convert_to_mod_dmg_type(category)
	var damage_mod: float = max(0, _mod_value_map[mod_type])

	return damage_mod


# NOTE: unit.getDamageToSize() in JASS
func get_damage_to_size(creep_size: CreepSize.enm) -> float:
	var mod_type: ModificationType.enm = CreepSize.convert_to_mod_dmg_type(creep_size)
	var damage_mod: float = max(0, _mod_value_map[mod_type])

	return damage_mod


func get_attack_type() -> AttackType.enm:
	return AttackType.enm.PHYSICAL

func get_exp() -> float:
	return _experience


func reached_max_level() -> bool:
	var is_max_level: bool = _level == Constants.MAX_LEVEL

	return is_max_level


func get_buff_groups(mode_list: Array) -> Array[int]:
	var result: Array[int] = []

# 	NOTE: need ordered iteration for determinism
	for buff_group in range(1, Constants.BUFFGROUP_COUNT + 1):
		var this_mode: BuffGroupMode.enm = _buff_groups[buff_group]
		if mode_list.has(this_mode):
			result.append(buff_group)

	return result


func set_buff_group_mode(buff_group: int, mode: BuffGroupMode.enm):
	if !_buff_groups.has(buff_group):
		push_error("Invalid buff group: ", buff_group)

		return

	_buff_groups[buff_group] = mode

	buff_group_changed.emit()


func get_buff_group_mode(buff_group: int) -> BuffGroupMode.enm:
	var mode: BuffGroupMode.enm = _buff_groups[buff_group]

	return mode
