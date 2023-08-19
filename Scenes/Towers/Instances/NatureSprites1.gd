extends Tower


# NOTE: in original game there's a discrepancy between value
# in description vs script. In description, item chance
# level bonus = 0.14%. In script it is 0.16%.


const EXP_RECEIVED: float = 0.28
const EXP_RECEIVED_ADD: float = 0.008
const SPELL_DAMAGE_DEALT: float = 0.16
const SPELL_DAMAGE_DEALT_ADD: float = 0.004
const ATK_CRIT_CHANCE: float = 0.04
const ATK_CRIT_CHANCE_ADD: float = 0.001
const DAMAGE_ADD_PERC: float = 0.16
const DAMAGE_ADD_PERC_ADD: float = 0.004
const BUFF_DURATION: float = 0.2
const BUFF_DURATION_ADD: float = 0.006
const ATTACKSPEED: float = 0.08
const ATTACKSPEED_ADD: float = 0.002
const ITEM_CHANCE: float = 0.06
const ITEM_CHANCE_ADD: float = 0.0014


var dave_gift: BuffType
var dave_sprite: ProjectileType


func get_tier_stats() -> Dictionary:
	return {
		1: {buff_strength = 1.0, projectile_scale = 0.75},
		2: {buff_strength = 1.5, projectile_scale = 1.5},
		3: {buff_strength = 2.0, projectile_scale = 1.5},
	}


func get_autocast_description() -> String:
	var exp_received: String = Utils.format_percent(EXP_RECEIVED, 2)
	var exp_received_add: String = Utils.format_percent(EXP_RECEIVED_ADD, 2)
	var spell_damage: String = Utils.format_percent(SPELL_DAMAGE_DEALT, 2)
	var spell_damage_add: String = Utils.format_percent(SPELL_DAMAGE_DEALT_ADD, 2)
	var crit_chance: String = Utils.format_percent(ATK_CRIT_CHANCE, 2)
	var crit_chance_add: String = Utils.format_percent(ATK_CRIT_CHANCE_ADD, 2)
	var damage_add_perc: String = Utils.format_percent(DAMAGE_ADD_PERC, 2)
	var damage_add_perc_add: String = Utils.format_percent(DAMAGE_ADD_PERC_ADD, 2)
	var buff_duration: String = Utils.format_percent(BUFF_DURATION, 2)
	var buff_duration_add: String = Utils.format_percent(BUFF_DURATION_ADD, 2)
	var attackspeed: String = Utils.format_percent(ATTACKSPEED, 2)
	var attackspeed_add: String = Utils.format_percent(ATTACKSPEED_ADD, 2)
	var item_chance: String = Utils.format_percent(ITEM_CHANCE, 2)
	var item_chance_add: String = Utils.format_percent(ITEM_CHANCE_ADD, 2)

	var text: String = ""

	text += "One of the spirits flies towards a tower in 500 range and buffs it for 5 seconds. The buff has a different effect depending on the tower's element:\n"
	text += "+%s experience for Astral\n" % exp_received
	text += "+%s spell damage for Darkness\n" % spell_damage
	text += "+%s crit chance for Nature\n" % crit_chance
	text += "+%s damage for Fire\n" % damage_add_perc
	text += "+%s buff duration for Ice\n" % buff_duration
	text += "+%s attack speed for Storm\n" % attackspeed
	text += "+%s item chance for Iron\n" % item_chance
	text += "The buffed tower has a 25%% chance to receive another random effect in addition to the first one.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s experience\n" % exp_received_add
	text += "+%s spell damage\n" % spell_damage_add
	text += "+%s crit chance\n" % crit_chance_add
	text += "+%s damage\n" % damage_add_perc_add
	text += "+%s buff duration\n" % buff_duration_add
	text += "+%s attack speed\n" % attackspeed_add
	text += "+%s item chance\n" % item_chance_add

	return text


func gift_create(event: Event):
	var B: Buff = event.get_buff()
	var target: Tower = B.get_buffed_unit()
	var tower: Tower = B.get_caster()
	var elem: int = target.get_category()
	var relem
	var level: int = B.get_level()
#	scale factor based on family member
	var member_modifier: float = tower.user_real

#	Ensure caster is still alive.
	if tower == null:
		return

	if elem == Element.enm.ASTRAL:
		B.user_int = Modification.Type.MOD_EXP_RECEIVED
		B.user_real = (EXP_RECEIVED + level * EXP_RECEIVED_ADD) * member_modifier
	elif elem == Element.enm.DARKNESS:
		B.user_int = Modification.Type.MOD_SPELL_DAMAGE_DEALT
		B.user_real = (SPELL_DAMAGE_DEALT + level * SPELL_DAMAGE_DEALT_ADD) * member_modifier
	elif elem == Element.enm.NATURE:
		B.user_int = Modification.Type.MOD_ATK_CRIT_CHANCE
		B.user_real = (ATK_CRIT_CHANCE + level * ATK_CRIT_CHANCE_ADD) * member_modifier
	elif elem == Element.enm.FIRE:
		B.user_int = Modification.Type.MOD_DAMAGE_ADD_PERC
		B.user_real = (DAMAGE_ADD_PERC + level * DAMAGE_ADD_PERC_ADD) * member_modifier
	elif elem == Element.enm.ICE:
		B.user_int = Modification.Type.MOD_BUFF_DURATION
		B.user_real = (BUFF_DURATION + level * BUFF_DURATION_ADD) * member_modifier
	elif elem == Element.enm.STORM:
		B.user_int = Modification.Type.MOD_ATTACKSPEED
		B.user_real = (ATTACKSPEED + level * ATTACKSPEED_ADD) * member_modifier
	elif elem == Element.enm.IRON:
		B.user_int = Modification.Type.MOD_ITEM_CHANCE_ON_KILL
		B.user_real = (ITEM_CHANCE + level * ITEM_CHANCE_ADD) * member_modifier

#	Apply the modification
	target.modify_property(B.user_int, B.user_real)

	if tower.calc_chance(0.25):
		relem = randi_range(0, 5)
#		Relem cannot be 6 (IRON), so we apply iron buff if elem == relem.
		if elem == relem:
			B.user_int = Modification.Type.MOD_ITEM_CHANCE_ON_KILL
			B.user_real = (ITEM_CHANCE + level * ITEM_CHANCE_ADD) * member_modifier
		elif elem == Element.enm.ASTRAL:
			B.user_int = Modification.Type.MOD_EXP_RECEIVED
			B.user_real = (EXP_RECEIVED + level * EXP_RECEIVED_ADD) * member_modifier
		elif elem == Element.enm.DARKNESS:
			B.user_int = Modification.Type.MOD_SPELL_DAMAGE_DEALT
			B.user_real = (SPELL_DAMAGE_DEALT + level * SPELL_DAMAGE_DEALT_ADD) * member_modifier
		elif elem == Element.enm.NATURE:
			B.user_int = Modification.Type.MOD_ATK_CRIT_CHANCE
			B.user_real = (ATK_CRIT_CHANCE + level * ATK_CRIT_CHANCE_ADD) * member_modifier
		elif elem == Element.enm.FIRE:
			B.user_int = Modification.Type.MOD_DAMAGE_ADD_PERC
			B.user_real = (DAMAGE_ADD_PERC + level * DAMAGE_ADD_PERC_ADD) * member_modifier
		elif elem == Element.enm.ICE:
			B.user_int = Modification.Type.MOD_BUFF_DURATION
			B.user_real = (BUFF_DURATION + level * BUFF_DURATION_ADD) * member_modifier
		elif elem == Element.enm.STORM:
			B.user_int = Modification.Type.MOD_ATTACKSPEED
			B.user_real = (ATTACKSPEED + level * ATTACKSPEED_ADD) * member_modifier

#		Apply the bonus modification
		target.modify_property(B.user_int2, B.user_real2)
		B.user_int3 = Effect.create_colored("KeeperGroveMissile.mdl", target.get_x(), target.get_y(), 150, 0, 0.9, Color8(255, 180, 180, 255)
	else:
		B.user_int2 = 0
		B.user_int3 = Effect.create_scaled("KeeperGroveMissile.mdl", target.get_x(), target.get_y(), 150, 0, 0.75)


func effect_clean(event: Event):
	var B: Buff = event.get_buff()
	var target: Tower = B.get_buffed_unit()
#	Remove the modification
	target.modify_property(B.user_int, -B.user_real)

	if B.user_int2 != 0:
#		Remove the bonus modification
		target.modify_property(B.user_int2, -B.user_real2)

	if B.user_int3 != 0:
		Effect.destroy_effect(B.user_int3)


func sprite_hit(P: Projectile, target: Unit):
	var tower: Tower = P.get_caster()
	dave_gift.apply(tower, target, tower.get_level())


func tower_init():
	dave_gift = BuffType.new("dave_gift", 5, 0, true, self)
	dave_gift.set_buff_icon("@@0@@")
	dave_gift.add_event_on_create(gift_create)
	dave_gift.set_event_on_cleanup(effect_clean)
#	TODO:
	dave_gift.set_buff_tooltip("Nature's Gift\nThis tower is affected by Nature's Gift; it has increased random stat.")

	dave_sprite = ProjectileType.create("KeeperGroveMissile.mdl", 4, 400)
	dave_sprite.enable_homing(sprite_hit, 0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Nature's Gift"
	autocast.description = get_autocast_description()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 5
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.cast_range = 500
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 2
	autocast.is_extended = false
	autocast.mana_cost = 45
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.auto_range = 500
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self
	var p: Projectile
	p = Projectile.create_from_unit_to_unit(dave_sprite, tower, 0, 0, tower, event.get_target(), true, false, false)
	p.setScale(_stats.projectile_scale)
# 	TODO:
# 	p.color(50, 255, 50, 255)


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
#	Member buff strength modifier
	tower.user_real = _stats.buff_strength
