class_name Unit
extends CharacterBody2D

# Unit is a base class for Towers and Creeps. Keeps track of
# buffs and modifications. Emits signals for events which are used by buffs.

# NOTE: can't use static typing for Buff because of cyclic
# dependency

signal level_up
signal attack(event)
signal attacked(event)
signal dealt_damage(event)
signal damaged(event)
signal kill(event)
signal death(event)
signal became_invisible()
signal became_visible()
signal health_changed()
signal mana_changed()
signal spell_casted(event: Event)
signal spell_targeted(event: Event)
signal earn_gold(amount: float, _mystery_bool_1: bool, _mystery_bool_2: bool)


signal selected()
signal unselected()


enum State {
	LIFE,
	MANA
}

enum DamageSource {
	Attack,
	Spell
}


const MULTICRIT_DIMINISHING_CHANCE: float = 0.8
const INVISIBLE_MODULATE: Color = Color(1, 1, 1, 0.5)
# TODO: replace this placeholder constant with real value.
const EXP_PER_LEVEL: float = 100
const REGEN_PERIOD: float = 1.0

var _sprite_area: Area2D = null
var _sprite_dimensions: Vector2 = Vector2.ZERO

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0

var _is_dead: bool = false
var _level: int = 1 : get = get_level, set = set_level
var _buff_type_map: Dictionary
var _buff_group_map: Dictionary
var _friendly_buff_list: Array[Buff]
var _unfriendly_buff_list: Array[Buff]
var _direct_modifier_list: Array
var _base_health: float = 100.0 : get = get_base_health, set = set_base_health
var _health: float = 0.0
var _base_health_regen: float = 1.0
var _invisible: bool = false
var _selected: bool = false : get = is_selected
var _experience: float = 0.0
var _mana: float = 0.0
# TODO: define real value
var _base_armor: float = 45.0
var _dealt_damage_signal_in_progress: bool = false
var _kill_count: int = 0
var _best_hit: float = 0.0
var _damage_dealt_total: float = 0.0
var _silence_count: int = 0
var _stunned: bool = false
var _visual_only: bool = false

var _selection_visual: Node = null

# This is the count of towers that are currently able to see
# this invisible creep. If there any towers that can see this
# creep, then it is considered to be visible to all towers.
# See Unit.is_invisible() f-n and MagicalSightBuff.
var _invisible_watcher_count: int = 0

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
	Modification.Type.MOD_ATK_CRIT_CHANCE: 0.01,
	Modification.Type.MOD_ATK_CRIT_DAMAGE: 1.5,
	Modification.Type.MOD_TRIGGER_CHANCES: 1.0,
	Modification.Type.MOD_SPELL_DAMAGE_DEALT: 1.0,
	Modification.Type.MOD_SPELL_DAMAGE_RECEIVED: 1.0,
	Modification.Type.MOD_SPELL_CRIT_DAMAGE: 1.5,
	Modification.Type.MOD_SPELL_CRIT_CHANCE: 0.01,
	Modification.Type.MOD_BOUNTY_GRANTED: 1.0,
	Modification.Type.MOD_BOUNTY_RECEIVED: 1.0,
	Modification.Type.MOD_EXP_GRANTED: 1.0,
	Modification.Type.MOD_EXP_RECEIVED: 1.0,
	Modification.Type.MOD_BUFF_DURATION: 1.0,
	Modification.Type.MOD_DEBUFF_DURATION: 1.0,
	Modification.Type.MOD_MOVESPEED: 1.0,
	Modification.Type.MOD_MOVESPEED_ABSOLUTE: 0.0,
	Modification.Type.MOD_MULTICRIT_COUNT: 1.0,
	Modification.Type.MOD_ATK_DAMAGE_RECEIVED: 1.0,
	Modification.Type.MOD_ATTACKSPEED: 1.0,
	Modification.Type.MOD_DPS_ADD: 0.0,

	Modification.Type.MOD_ITEM_CHANCE_ON_KILL: 0.0,
	Modification.Type.MOD_ITEM_QUALITY_ON_KILL: 0.0,
	Modification.Type.MOD_ITEM_CHANCE_ON_DEATH: 0.0,
	Modification.Type.MOD_ITEM_QUALITY_ON_DEATH: 0.0,

	Modification.Type.MOD_ARMOR: 0.0,
	Modification.Type.MOD_ARMOR_PERC: 1.0,

	Modification.Type.MOD_DAMAGE_BASE: 0.0,
	Modification.Type.MOD_DAMAGE_BASE_PERC: 1.0,
	Modification.Type.MOD_DAMAGE_ADD: 0.0,
	Modification.Type.MOD_DAMAGE_ADD_PERC: 1.0,

	Modification.Type.MOD_MANA: 0.0,
	Modification.Type.MOD_MANA_PERC: 1.0,
	Modification.Type.MOD_MANA_REGEN: 0.0,
	Modification.Type.MOD_MANA_REGEN_PERC: 1.0,
	Modification.Type.MOD_HP: 0.0,
	Modification.Type.MOD_HP_PERC: 1.0,
	Modification.Type.MOD_HP_REGEN: 0.0,
	Modification.Type.MOD_HP_REGEN_PERC: 1.0,

	Modification.Type.MOD_DMG_TO_MASS: 1.0,
	Modification.Type.MOD_DMG_TO_NORMAL: 1.0,
	Modification.Type.MOD_DMG_TO_CHAMPION: 1.0,
	Modification.Type.MOD_DMG_TO_BOSS: 1.0,
	Modification.Type.MOD_DMG_TO_AIR: 1.0,

	Modification.Type.MOD_DMG_TO_UNDEAD: 1.0,
	Modification.Type.MOD_DMG_TO_MAGIC: 1.0,
	Modification.Type.MOD_DMG_TO_NATURE: 1.0,
	Modification.Type.MOD_DMG_TO_ORC: 1.0,
	Modification.Type.MOD_DMG_TO_HUMANOID: 1.0,

	Modification.Type.MOD_DMG_FROM_ASTRAL: 1.0,
	Modification.Type.MOD_DMG_FROM_DARKNESS: 1.0,
	Modification.Type.MOD_DMG_FROM_NATURE: 1.0,
	Modification.Type.MOD_DMG_FROM_FIRE: 1.0,
	Modification.Type.MOD_DMG_FROM_ICE: 1.0,
	Modification.Type.MOD_DMG_FROM_STORM: 1.0,
	Modification.Type.MOD_DMG_FROM_IRON: 1.0,
}


@onready var _owner: Player = get_tree().get_root().get_node("GameScene/Player")


#########################
### Code starts here  ###
#########################


func _init():
	for mod_type in Modification.Type.values():
		if !_mod_value_map.has(mod_type):
			push_error("No default value defined for modification type: ", mod_type)

func _ready():
	if _visual_only:
		return

	_selection_visual = Selection.new()
	_selection_visual.hide()
	_selection_visual.z_index = -1
	add_child(_selection_visual)
	
	var regen_timer: Timer = Timer.new()
	regen_timer.one_shot = false
	regen_timer.wait_time = REGEN_PERIOD
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)
	regen_timer.start()

#	NOTE: mana starts at 0 on purpose, so that newly built
#	towers need to regene mana first before they can use it.
	_mana = 0
	_health = get_overall_health()

	var triggers_buff_type: BuffType = BuffType.new("", 0, 0, true, self)
	load_triggers(triggers_buff_type)
	triggers_buff_type.apply_to_unit_permanent(self, self, 0)


#########################
###       Public      ###
#########################


func add_mana_perc(ratio: float):
	var overall_mana: float = get_overall_mana()
	var mana_added: float = ratio * overall_mana
	add_mana(mana_added)


func add_mana(mana_added: float):
	var new_mana: float = _mana + mana_added
	_set_mana(new_mana)


# TODO: implement. Hard to understand how this is supposed
# to work.
func add_spell_crit():
	pass


func add_autocast(autocast: Autocast):
	autocast.set_caster(self)
	add_child(autocast)


func add_aura(aura_type: AuraType):
	var aura: Aura = aura_type.make(self)
	add_child(aura)


# NOTE: for now just returning the one single player
# instance since multiplayer isn't implemented.
func getOwner() -> Player:
	return _owner


# NOTE: this is a stub, used in original tower scripts but
# not needed in godot engine.
func set_animation_by_index(_unit: Unit, _index: int):
	pass


# Unaffected by tower exp ratios. Levels up unit if added
# exp pushes the unit past the level up threshold.
func add_exp_flat(amount: float):
	_experience += amount

	var leveled_up: bool = false

	if _experience >= EXP_PER_LEVEL:
		_experience -= EXP_PER_LEVEL

		var new_level: int = _level + 1
		set_level(new_level)
		level_up.emit()

		var effect_id: int = Effect.create_simple_at_unit("res://Scenes/Effects/LevelUp.tscn", self)
		var effect_scale: float = max(_sprite_dimensions.x, _sprite_dimensions.y) / Constants.LEVEL_UP_EFFECT_SIZE
		Effect.scale_effect(effect_id, effect_scale)
		Effect.destroy_effect(effect_id)

		var level_up_text: String = "Level %d" % _level
		getOwner().display_floating_text_color(level_up_text, self, Color.GOLD , 1.0)
		leveled_up = true

		SFX.sfx_at_unit("res://Assets/SFX/level_up.mp3", self)


	if !leveled_up:
		var exp_text: String = "+%s exp" % String.num(amount, 1)
		getOwner().display_floating_text_color(exp_text, self, Color.LIME_GREEN, 1.0)


# Affected by tower exp ratios.
func add_exp(amount_no_bonus: float):
	var received_mod: float = get_prop_exp_received()
	var amount: float = amount_no_bonus * received_mod
	add_exp_flat(amount)


# Unaffected by tower exp ratios. Returns how much
# experience was actually removed. How much was actually
# removed may be less than requested if the unit has less
# mana than should be removed. In that case unit's mana gets
# set to 0.
func remove_exp_flat(amount: float) -> float:
	var old_exp: float = _experience
	var new_exp: float = clampf(_experience - amount, 0.0, _experience)
	_experience = new_exp

	var actual_removed: float = old_exp - new_exp

	return actual_removed


# Affected by "exp recieved" modification.
func remove_exp(amount_no_bonus: float):
	var received_mod: float = get_prop_exp_received()
	var amount: float = amount_no_bonus * received_mod
	remove_exp_flat(amount)


func calc_chance(chance_base: float) -> bool:
	var mod_trigger_chances: float = get_prop_trigger_chances()
	var chance: float = chance_base * mod_trigger_chances
	var success: bool = Utils.rand_chance(chance)

	return success


# "Bad" chance is for events that decrease tower's
# perfomance, for example missing attack. Bad chances are
# unaffected by Modification.Type.MOD_TRIGGER_CHANCES.
func calc_bad_chance(chance: float) -> bool:
	var success: bool = Utils.rand_chance(chance)

	return success


func calc_spell_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_spell_crit_chance() + bonus_chance
	var crit_damage: float = get_spell_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(crit_chance)

	if crit_success:
		return crit_damage
	else:
		return 1.0


func calc_spell_crit_no_bonus() -> float:
	var result: float = calc_spell_crit(0.0, 0.0)

	return result


# Returns a randomly calculate crit bonus, no multicrit,
# either crit or not crit.
func calc_attack_crit(bonus_chance: float, bonus_damage: float) -> float:
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

	var crit_success: bool = Utils.rand_chance(crit_chance)

	if crit_success:
		return crit_damage
	else:
		return 1.0


func calc_attack_crit_no_bonus() -> float:
	var result: float = calc_spell_crit(0.0, 0.0)

	return result


# Returns a randomly calculated crit bonus (starts at 1.0),
# taking into account multicrit.
# 0 crits, 150% crit damage = 1.0
# 1 crit, 150% crit damage = 1.5
# 3 crits, 150% crit damage = 1.0 + 0.5 + 0.5 + 0.5 = 2.5
func calc_attack_multicrit(bonus_multicrit: float, bonus_chance: float, bonus_damage: float) -> float:
	var crit_count: int = _generate_crit_count(bonus_multicrit, bonus_chance)
	var crit_damage: float = _calc_attack_multicrit_internal(crit_count, bonus_damage)

	return crit_damage


static func get_spell_damage(damage_base: float, crit_ratio: float, caster: Unit, target: Unit) -> float:
	var dealt_mod: float = caster.get_prop_spell_damage_dealt()
	var received_mod: float = target.get_prop_spell_damage_received()
	var damage_total: float = damage_base * dealt_mod * received_mod * crit_ratio

#	TODO: didn't actually confirm whether immune = doesn't
#	receive spell damage. Confirm.
	if target.is_immune():
		damage_total = 0

	return damage_total


func do_spell_damage(target: Unit, damage: float, crit_ratio: float):
	var damage_total: float = Unit.get_spell_damage(damage, crit_ratio, self, target)

	_do_damage(target, damage_total, DamageSource.Spell)


func do_attack_damage(target: Unit, damage_base: float, crit_ratio: float):
	_do_attack_damage_internal(target, damage_base, crit_ratio, false)


func _do_attack_damage_internal(target: Unit, damage_base: float, crit_ratio: float, is_main_target: bool):
	var armor_mod: float = target.get_current_armor_damage_reduction()
	var received_mod: float = target.get_prop_atk_damage_received()
	var element_mod: float = 1.0

	if self is Tower:
		var tower: Tower = self as Tower
		var element: Element.enm = tower.get_element()
		var mod_type: Modification.Type = Element.convert_to_dmg_from_element_mod(element)
		element_mod = target._mod_value_map[mod_type]

	var damage: float = damage_base * armor_mod * received_mod * element_mod

	var attack_type: AttackType.enm = get_attack_type()
	var deals_no_damage_to_immune: bool = AttackType.deals_no_damage_to_immune(attack_type)

	if target.is_immune() && deals_no_damage_to_immune:
		damage = 0

#   NOTE: do not emit damage event if one is already in
#   progress. Some towers have damage event handlers that
#   call doAttackDamage() so recursive damage events would
#   cause infinite recursion.
	if !_dealt_damage_signal_in_progress:
		_dealt_damage_signal_in_progress = true

		var damage_event: Event = Event.new(target)
		damage_event.damage = damage
		damage_event._is_main_target = is_main_target
		dealt_damage.emit(damage_event)
		damage = damage_event.damage

		_dealt_damage_signal_in_progress = false

#	NOTE: according to this comment in one tower script,
#	crit bonus damage should be applied after damage event:
#
# 	Quote: "The engine calculates critical strike extra
# 	damage ***AFTER*** the onDamage event, so there is no
# 	need to care about it in this trigger."
	damage *= crit_ratio

	_do_damage(target, damage, DamageSource.Attack)


# NOTE: sides_ratio parameter specifies how much less damage
# is dealt to units that are on the "sides" of the aoe
# circle. For example, if sides_ratio is set to 0.3 then
# units on the sides will receive 30% less damage than those
# in the center.
func do_attack_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), target.position, radius)

	for creep in creep_list:
		var damage_for_creep: float = _get_aoe_damage(creep, radius, damage, sides_ratio)
		do_attack_damage(creep, damage_for_creep, crit_ratio)


func do_spell_damage_aoe_unit(target: Unit, radius: float, damage: float, crit_ratio: float, sides_ratio: float):
	var creep_list: Array = Utils.get_units_in_range(TargetType.new(TargetType.CREEPS), target.position, radius)

	for creep in creep_list:
		var damage_for_creep: float = _get_aoe_damage(creep, radius, damage, sides_ratio)
		do_spell_damage(creep, damage_for_creep, crit_ratio)

func kill_instantly(target: Unit):
	target._killed_by_unit(self)


func modify_property(mod_type: Modification.Type, value: float):
	_modify_property_internal(mod_type, value, 1)


func _modify_property_internal(mod_type: Modification.Type, value: float, direction: int):
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

	_on_modify_property()


# NOTE: this modifies only creep's ability to be invisible.
# It won't be invisible if the creep is within range of
# towers that can see invisible units.
func set_invisible(invisible: bool):
	_invisible = invisible
	_update_invisible_modulate()


# These two functions are used to implement magical sight
# effects.
func add_invisible_watcher():
	_invisible_watcher_count += 1
	_update_invisible_modulate()

	if !is_invisible():
		became_visible.emit()


func remove_invisible_watcher():
	_invisible_watcher_count -= 1
	_update_invisible_modulate()

	if is_invisible():
		became_invisible.emit()


# TODO: silence visual. When silence_count changes from 0 to
# 1, create it and schedule to destroy it once animation
# finishes. Idea for how it should look:
# https://youtu.be/zUCL-_6YOT8?t=46
func add_silence():
	_silence_count += 1


func remove_silence():
	_silence_count -= 1


func set_stunned(value: bool):
	_stunned = value


func spend_mana(mana_cost: float):
	_set_mana(_mana - mana_cost)


# NOTE: this f-n exists for compatiblity with original API
# used in tower scripts
static func get_unit_state(unit: Unit, state: Unit.State) -> float:
	match state:
		Unit.State.LIFE: return unit._health
		Unit.State.MANA: return unit._mana

	return 0.0


static func set_unit_state(unit: Unit, state: Unit.State, value: float):
	match state:
		Unit.State.LIFE: unit._set_health(value)
		Unit.State.MANA: unit._set_mana(value)


#########################
###      Private      ###
#########################


# Generates a random crit count. Different number every
# time.
func _generate_crit_count(bonus_multicrit: float, bonus_chance: float) -> int:
	var multicrit_count_max: int = get_prop_multicrit_count() + int(bonus_multicrit)
	var crit_chance: float = get_prop_atk_crit_chance() + bonus_chance

	var crit_count: int = 0
	var current_crit_chance: float = crit_chance
	
	for _i in range(multicrit_count_max):
		var is_critical: bool = Utils.rand_chance(current_crit_chance)

		if is_critical:
			crit_count += 1

#			Decrease chance of each subsequent multicrit to
#			implement diminishing returns.
			current_crit_chance *= MULTICRIT_DIMINISHING_CHANCE
		else:
			break

	return crit_count


# Same as calc_attack_multicrit(), but accepts an already
# calculated crit count. Used by Tower.
func _calc_attack_multicrit_internal(crit_count: int, bonus_damage: float) -> float:
	var crit_damage: float = get_prop_atk_crit_damage() + bonus_damage

# 	NOTE: subtract 1.0 from crit_damage, so we do
#	1.0 + 0.5 + 0.5 + 0.5...
# 	not
#	1.0 + 1.5 + 1.5 + 1.5...
	var total_crit_damage: float = 1.0 + (crit_damage - 1.0) * crit_count

	total_crit_damage = max(0.0, total_crit_damage)

	return total_crit_damage


# Call this (or the animated sprite version) in subclass to
# set the main sprite for the unit. This sprite will be used
# to detect collison with mouse and also as the visual
# position of the unit.
func _set_unit_sprite(sprite: Sprite2D, override_area: Area2D = null):
	var texture: Texture2D = sprite.texture
	var image: Image = texture.get_image()

	_set_unit_sprite_internal(image, sprite, override_area)


# TODO: using first frame from first animation but this is
# inaccurate if different frames occupy different parts of
# the image. Maybe overlay all frames into a special frame
# that is the "average", durin generation from blender?
func _set_unit_animted_sprite(sprite: AnimatedSprite2D):
	var sprite_frames: SpriteFrames = sprite.sprite_frames
	var animation_name_list: PackedStringArray = sprite_frames.get_animation_names()

	if animation_name_list.size() == 0:
		print_debug("No animations except default, can't setup selection shape.")

		return

	var animation: String = animation_name_list[0]
	var texture: Texture2D = sprite_frames.get_frame_texture(animation, 0)
	var image: Image = texture.get_image()

	_set_unit_sprite_internal(image, sprite, null)


# Generate a rectangle shape that encloses used portion of
# sprite's texture. Used portion means pixels with non-zero
# alpha. Also save dimensions of used region in the sprite.
func _set_unit_sprite_internal(image: Image, sprite_node: Node2D, override_area: Area2D):
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	collision_shape.shape = shape

	var used_rect: Rect2i = image.get_used_rect()

	shape.size = used_rect.size

# 	NOTE: Rect2i position is top-left corner, so need to do
# 	some math to calculate correct offset for area2d
	_sprite_area = Area2D.new()
	_sprite_area.add_child(collision_shape)
	_sprite_area.position = used_rect.position + used_rect.size / 2 - image.get_size() / 2

#	NOTE: use sprite as parent for area2d so so that the
#	position of area2d matches sprite's position
	sprite_node.add_child(_sprite_area)
	_sprite_dimensions = Vector2(used_rect.size) * sprite_node.scale

	if override_area != null:
		override_area.mouse_entered.connect(SelectUnit.on_unit_mouse_entered.bind(self))
		override_area.mouse_exited.connect(SelectUnit.on_unit_mouse_exited.bind(self))
		
# All towers should have unified selector size
		_selection_visual.visual_size = 128
	else:
		_sprite_area.mouse_entered.connect(SelectUnit.on_unit_mouse_entered.bind(self))
		_sprite_area.mouse_exited.connect(SelectUnit.on_unit_mouse_exited.bind(self))

		_selection_visual.visual_size = _sprite_dimensions.x


func set_hovered(hovered: bool):
	if _selected:
		return

	_selection_visual.modulate = Color.WHITE
	_selection_visual.set_visible(hovered)


# NOTE: override this in subclass to attach trigger handlers
# to triggers buff passed in the argument.
func load_triggers(_triggers_buff_type: BuffType):
	pass


func _set_mana(new_mana: float):
	var overall_mana: float = get_overall_mana()
	_mana = clampf(new_mana, 0.0, overall_mana)
	mana_changed.emit()


func _set_health(new_health: float):
	var overall_health: float = get_overall_health()
	_health = clampf(new_health, 0.0, overall_health)
	health_changed.emit()


func _get_aoe_damage(target: Unit, radius: float, damage: float, sides_ratio: float) -> float:
	var distance: float = Isometric.vector_distance_to(position, target.position)
	var target_is_on_the_sides: bool = (distance / radius) > 0.5

	if target_is_on_the_sides:
		return damage * (1.0 - sides_ratio)
	else:
		return damage


func _on_regen_timer_timeout():
	var mana_regen: float = get_overall_mana_regen()
	_set_mana(_mana + mana_regen)

	var health_regen: float = get_overall_health_regen()
	_set_health(_health + health_regen)


func _do_attack(attack_event: Event):
	attack.emit(attack_event)

	var target = attack_event.get_target()
	target._receive_attack()


func _receive_attack():
	var attacked_event: Event = Event.new(self)
	attacked.emit(attacked_event)


func _do_damage(target: Unit, damage_base: float, damage_source: DamageSource):
	var size_mod: float = _get_damage_mod_for_creep_size(target)
	var category_mod: float = _get_damage_mod_for_creep_category(target)
	var armor_type_mod: float = _get_damage_mod_for_creep_armor_type(target)

	var damage: float = damage_base * size_mod * category_mod * armor_type_mod

	var damaged_event: Event = Event.new(self)
	damaged_event.damage = damage
	damaged_event._is_spell_damage = damage_source == DamageSource.Spell
	target.damaged.emit(damaged_event)

	damage = damaged_event.damage

	_damage_dealt_total += damage

	if damage > _best_hit:
		_best_hit = damage

	var damage_killed_unit: bool = target.receive_damage(damage)

	if damage_killed_unit:
		target._killed_by_unit(self)


# NOTE: this f-n is also used by
# DummyUnit.do_spell_damage(), so it can't emit "damaged" or
# "killed_by" events because DummyUnit is not a subclass of
# Unit so creep is technically not killed or damaged by any
# unit in such cases.
func receive_damage(damage: float) -> bool:
	var health_before_damage: float = _health

	_set_health(_health - damage)

	if Config.damage_numbers():
		getOwner().display_floating_text_color(str(int(damage)), self, Color.RED, 1.0)

	var damage_killed_unit: bool = health_before_damage > 0 && _health <= 0

	return damage_killed_unit


# Called when unit killed by caster unit
func _killed_by_unit(caster: Unit):
# 	NOTE: need to use explicit "is_dead" flag. Calling
# 	queue_free() makes is_instance_valid(unit) return false
# 	but that happens only at the end of the current frame.
# 	Other signals/slots might fire before that point and
# 	they need to know if the unit is dead to avoid
# 	processing it.
	_is_dead = true

	var death_event: Event = Event.new(caster)
	death.emit(death_event)

	if caster != null:
		caster._accept_kill(self)

	var caster_item_chance: float = caster.get_item_drop_ratio()
	var target_item_chance: float = get_item_drop_ratio_on_death()
	var item_chance: float = caster_item_chance + target_item_chance

	var item_dropped: bool = Utils.rand_chance(item_chance) || Config.always_drop_items()
	var creep: Creep = self as Creep

	if item_dropped && creep != null:
		creep.drop_item(caster, false)

	queue_free()


# Called when unit kills target unit
func _accept_kill(target: Unit):
	var experience_gained: float = _get_experience_for_target(target)
	add_exp(experience_gained)

	_kill_count += 1

	var kill_event: Event = Event.new(target)
	kill.emit(kill_event)


# This is for internal use in Buff.gd only. For external
# use, call Buff.apply_to_unit().
func _add_buff_internal(buff: Buff):
	var buff_type: String = buff.get_type()
	_buff_type_map[buff_type] = buff

	var stacking_group: String = buff.get_stacking_group()
	_buff_group_map[stacking_group] = buff

	var friendly: bool = buff.is_friendly()
	_get_buff_list(friendly).append(buff)
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), 1)
	add_child(buff)


func _apply_modifier(modifier: Modifier, power: int, modify_direction: int):
	var modification_list: Array = modifier.get_modification_list()

	for modification in modification_list:
		var power_bonus: float = modification.level_add * (power - 1)
		var value: float = modification.value_base + power_bonus

		_modify_property_internal(modification.type, value, modify_direction)


func _update_invisible_modulate():
	if is_invisible():
		modulate = INVISIBLE_MODULATE
	else:
		modulate = Color(1, 1, 1, 1)


func get_bounty() -> float:
# 	TODO: Replace this placeholder constant with real value.
	var bounty_base: float = 10.0
	var granted_mod: float = get_prop_bounty_granted()
	var received_mod: float = get_prop_bounty_received()
	var bounty: int = int(bounty_base * granted_mod * received_mod)

	return bounty


func _get_experience_for_target(target: Unit) -> float:
# 	TODO: Replace this placeholder constant with real value.
	var experience_base: float = 10.0
	var granted_mod: float = target.get_prop_exp_granted()
	var experience: float = experience_base * granted_mod

	return experience


func _get_buff_list(friendly: bool) -> Array[Buff]:
	if friendly:
		return _friendly_buff_list
	else:
		return _unfriendly_buff_list


#########################
###     Callbacks     ###
#########################

func _remove_buff_internal(buff: Buff):
	var buff_modifier: Modifier = buff.get_modifier()
	_apply_modifier(buff_modifier, buff.get_power(), -1)

	var buff_type: String = buff.get_type()
	_buff_type_map.erase(buff_type)

	var stacking_group: String = buff.get_stacking_group()
	_buff_group_map.erase(stacking_group)

	var friendly: bool = buff.is_friendly()
	_get_buff_list(friendly).erase(buff)
	buff.queue_free()

func _on_modify_property():
	pass


#########################
### Setters / Getters ###
#########################

func is_immune() -> bool:
	return false

# Adds modifier directly to unit. Modifier will
# automatically scale with this unit's level. If you need to
# make a modifier that scales with another unit's level, use
# buffs.
func add_modifier(modifier: Modifier):
	_apply_modifier(modifier, _level, 1)
	_direct_modifier_list.append(modifier)


func remove_modifier(modifier: Modifier):
	if _direct_modifier_list.has(modifier):
		_apply_modifier(modifier, _level, -1)
		_direct_modifier_list.append(modifier)


func set_level(new_level: int):
	var old_level: int = _level
	_level = new_level

#	NOTE: apply level change to modifiers
	for modifier in _direct_modifier_list:
		_change_modifier_level(modifier, old_level, new_level)


func _change_modifier_level(modifier: Modifier, old_level: int, new_level: int):
	_apply_modifier(modifier, old_level, -1)
	_apply_modifier(modifier, new_level, 1)


func is_dead() -> bool:
	return _is_dead


# NOTE: use this instead of regular Node2D.position for
# anything involving visual effects, so projectiles and
# spell effects. Do NOT use visual position for game
# "physics", for example calculating distance between units.
# Game physics need to be performed in 2D space, so use
# regular "position".
func get_visual_position() -> Vector2:
	if _sprite_area != null:
		return _sprite_area.global_position
	else:
		return global_position

# Returns approximate position of the body part of unit in
# the world. Accepts "origin", "chest" or "head".
# NOTE: body parts were used in original API based on
# coordinates of body parts of 3D models. Approximate this
# feature for 2d tiles by defining body part positions as:
# "origin" = bottom of sprite
# "chest" = middle of sprite
# "head" = top of sprite
# Note that "sprite" here means the occupied part of the
# texture. Some sprites occupy only a small portion of the
# total texture so using texture center/dimensions would
# cause incorrect results.
func get_body_part_position(body_part: String) -> Vector2:
	if _sprite_area == null:
		print_debug("No selection area2d defined")

		return get_visual_position()

	var sprite_center: Vector2 = _sprite_area.global_position
	var sprite_height: float = float(_sprite_dimensions.y)

	match body_part:
		"head": return sprite_center - Vector2(0, sprite_height / 2)
		"chest": return sprite_center
		"origin": return sprite_center + Vector2(0, sprite_height / 2)
		_:
			push_error("Unhandled body part: ", body_part)

			return get_visual_position()

func get_x() -> float:
	return position.x


func get_y() -> float:
	return position.y


# NOTE: Getters for mod values are used in TowerTooltip.
# Getter names need to match the names of label nodes that
# display the values. For example if getter name is
# get_prop_trigger_chances(), then label name must be
# PropTriggerChances.

func get_prop_buff_duration() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_BUFF_DURATION])

func get_prop_debuff_duration() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DEBUFF_DURATION])

func get_prop_atk_crit_chance() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ATK_CRIT_CHANCE])

func get_prop_atk_crit_damage() -> float:
	return max(1.0, _mod_value_map[Modification.Type.MOD_ATK_CRIT_DAMAGE])

# Returns the value of the average damage multipler based on crit chance, crit damage
# and multicrit count of the tower
func get_crit_multiplier() -> float:
	return 1 + get_prop_atk_crit_chance() * get_prop_atk_crit_damage()

func get_prop_bounty_received() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_BOUNTY_RECEIVED])

func get_prop_bounty_granted() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_BOUNTY_GRANTED])

func get_prop_exp_received() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_EXP_RECEIVED])

func get_prop_exp_granted() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_EXP_GRANTED])

func get_damage_to_air() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_AIR])

func get_damage_to_boss() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_BOSS])

func get_damage_to_mass() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_MASS])

func get_damage_to_normal() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_NORMAL])

func get_damage_to_champion() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_CHAMPION])

func get_damage_to_undead() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_UNDEAD])

func get_damage_to_humanoid() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_HUMANOID])

func get_damage_to_nature() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_NATURE])

func get_damage_to_magic() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_MAGIC])

func get_damage_to_orc() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DMG_TO_ORC])

func get_exp_ratio() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_EXP_RECEIVED])

func get_item_drop_ratio() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ITEM_CHANCE_ON_KILL])

func get_item_quality_ratio() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ITEM_QUALITY_ON_KILL])

func get_item_drop_ratio_on_death() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ITEM_CHANCE_ON_DEATH])

func get_item_quality_ratio_on_death() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ITEM_QUALITY_ON_DEATH])

func get_prop_trigger_chances() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_TRIGGER_CHANCES])

func get_prop_multicrit_count() -> int:
	return int(max(0, _mod_value_map[Modification.Type.MOD_MULTICRIT_COUNT]))

func get_prop_spell_damage_dealt() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_DEALT])

func get_prop_spell_damage_received() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_SPELL_DAMAGE_RECEIVED])

func get_spell_crit_chance() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_SPELL_CRIT_CHANCE])

func get_spell_crit_damage() -> float:
	return max(1.0, _mod_value_map[Modification.Type.MOD_SPELL_CRIT_DAMAGE])

# Returns current value of "attack speed" stat which scales
# tower's attack cooldown. Note that even though name
# contains "base", this f-n returns value which includes
# modifiers.
func get_base_attack_speed() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ATTACKSPEED])

func get_level() -> int:
	return _level

func is_invisible() -> bool:
	return _invisible && _invisible_watcher_count == 0

func is_silenced() -> bool:
	return _silence_count > 0

func is_stunned() -> bool:
	return _stunned

# NOTE: overriden in Tower and Creep subclasses
func is_attacking() -> bool:
	return false

func get_buff_of_type(buff_type: BuffType) -> Buff:
	var type: String = buff_type.get_type()
	var buff = _buff_type_map.get(type, null)

	return buff


func get_buff_of_group(stacking_group: String) -> Buff:
	var buff = _buff_group_map.get(stacking_group, null)

	return buff


# Removes the most recent buff. Returns true if there was a
# buff to remove and false otherwise.
func purge_buff(friendly: bool) -> bool:
	var buff_list: Array[Buff] = _get_buff_list(friendly)

	var purgable_list: Array[Buff] = []

	for buff in buff_list:
		if buff.is_purgable():
			purgable_list.append(buff)

#	NOTE: buff is removed from the list further down the
#	chain from purge_buff() call.
	if !purgable_list.is_empty():
		var buff: Buff = purgable_list.back()
		buff.purge_buff()
		
		return true
	else:
		return false

# NOTE: real value returned in subclass version
func get_base_mana() -> float:
	return 0.0

func get_base_mana_bonus():
	return _mod_value_map[Modification.Type.MOD_MANA]

func get_base_mana_bonus_percent():
	return max(0, _mod_value_map[Modification.Type.MOD_MANA_PERC])

func get_overall_mana():
	return max(0, (get_base_mana() + get_base_mana_bonus()) * get_base_mana_bonus_percent())

# Returns current percentage of mana
func get_mana_ratio() -> float:
	var overall_mana: float = get_overall_mana()
	var ratio: float = Utils.get_ratio(_mana, overall_mana)

	return ratio


# NOTE: real value returned in subclass version
func get_base_mana_regen() -> float:
	return 0.0

func get_base_mana_regen_bonus():
	return max(0, _mod_value_map[Modification.Type.MOD_MANA_REGEN])

func get_base_mana_regen_bonus_percent():
	return max(0, _mod_value_map[Modification.Type.MOD_MANA_REGEN_PERC])

func get_overall_mana_regen():
	return (get_base_mana_regen() + get_base_mana_regen_bonus()) * get_base_mana_regen_bonus_percent()

func get_health() -> float:
	return _health

func get_base_health():
	return _base_health

func set_base_health(value: float):
	_base_health = value

func get_base_health_bonus():
	return _mod_value_map[Modification.Type.MOD_HP]

func get_base_health_bonus_percent():
	return max(0, _mod_value_map[Modification.Type.MOD_HP_PERC])

func get_overall_health():
	return max(0, (get_base_health() + get_base_health_bonus()) * get_base_health_bonus_percent())

# Returns current percentage of health
func get_health_ratio() -> float:
	var overall_health: float = get_overall_health()
	var ratio: float = Utils.get_ratio(_health, overall_health)

	return ratio

func get_base_health_regen():
	return _base_health_regen

func get_base_health_regen_bonus():
	return max(0, _mod_value_map[Modification.Type.MOD_HP_REGEN])

func get_base_health_regen_bonus_percent():
	return max(0, _mod_value_map[Modification.Type.MOD_HP_REGEN_PERC])

func get_overall_health_regen():
	return (get_base_health_regen() + get_base_health_regen_bonus()) * get_base_health_regen_bonus_percent()

func get_prop_move_speed() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_MOVESPEED])

func get_prop_move_speed_absolute() -> float:
	return _mod_value_map[Modification.Type.MOD_MOVESPEED_ABSOLUTE]

func get_prop_atk_damage_received() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ATK_DAMAGE_RECEIVED])

func get_display_name() -> String:
	return "Generic Unit"

func is_selected() -> bool:
	return _selected

func set_selected(selected_arg: bool):
	var selection_color: Color
	if self is Creep:
		selection_color = Color.RED
	else:
		selection_color = Color.GREEN

	_selection_visual.modulate = selection_color
	_selection_visual.set_visible(selected_arg)
	_selected = selected_arg

	if selected_arg:
		selected.emit()
	else:
		unselected.emit()

# Implemented by Tower and Creep to return tower element or
# creep category
# NOTE: because Tower and Creep return different enum types
# have to use typing for int here.
func get_category() -> int:
	return 0

func get_base_damage_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_DAMAGE_BASE]

func get_base_damage_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DAMAGE_BASE_PERC])

func get_damage_add() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DAMAGE_ADD])

func get_damage_add_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_DAMAGE_ADD_PERC])

# TODO: implement real formula
func get_current_armor_damage_reduction() -> float:
	var armor: float = get_overall_armor()
	var reduction: float = max(1.0, armor / 1000.0)

	return reduction

func get_mana() -> float:
	return _mana

func get_base_armor() -> float:
	return _base_armor

func get_base_armor_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_ARMOR]

func get_base_armor_bonus_percent() -> float:
	return max(0, _mod_value_map[Modification.Type.MOD_ARMOR_PERC])

func get_overall_armor():
	return (get_base_armor() + get_base_armor_bonus()) * get_base_armor_bonus_percent()

func get_dps_bonus() -> float:
	return _mod_value_map[Modification.Type.MOD_DPS_ADD]

func _get_damage_mod_for_creep_category(creep: Creep) -> float:
	const creep_category_to_mod_map: Dictionary = {
		CreepCategory.enm.UNDEAD: Modification.Type.MOD_DMG_TO_MASS,
		CreepCategory.enm.MAGIC: Modification.Type.MOD_DMG_TO_MAGIC,
		CreepCategory.enm.NATURE: Modification.Type.MOD_DMG_TO_NATURE,
		CreepCategory.enm.ORC: Modification.Type.MOD_DMG_TO_ORC,
		CreepCategory.enm.HUMANOID: Modification.Type.MOD_DMG_TO_HUMANOID,
	}

	var creep_category: CreepCategory.enm = creep.get_category() as CreepCategory.enm
	var mod_type: Modification.Type = creep_category_to_mod_map[creep_category]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod

func _get_damage_mod_for_creep_armor_type(creep: Creep) -> float:
	var attack_type: AttackType.enm = get_attack_type()
	var armor_type: ArmorType.enm = creep.get_armor_type()
	var damage_mod: float = AttackType.get_damage_against(attack_type, armor_type)

	return damage_mod

func _get_damage_mod_for_creep_size(creep: Creep) -> float:
	const creep_size_to_mod_map: Dictionary = {
		CreepSize.enm.MASS: Modification.Type.MOD_DMG_TO_MASS,
		CreepSize.enm.NORMAL: Modification.Type.MOD_DMG_TO_NORMAL,
		CreepSize.enm.CHAMPION: Modification.Type.MOD_DMG_TO_CHAMPION,
		CreepSize.enm.BOSS: Modification.Type.MOD_DMG_TO_BOSS,
		CreepSize.enm.AIR: Modification.Type.MOD_DMG_TO_AIR,
	}

	var creep_size: CreepSize.enm = creep.get_size()
	var mod_type: Modification.Type = creep_size_to_mod_map[creep_size]
	var damage_mod: float = _mod_value_map[mod_type]

	return damage_mod

func get_attack_type() -> AttackType.enm:
	return AttackType.enm.PHYSICAL

func get_exp() -> float:
	return _experience

func get_experience_for_next_level():
	var for_next_level: float = EXP_PER_LEVEL - _experience

	return for_next_level

func get_uid() -> int:
	return get_instance_id()
