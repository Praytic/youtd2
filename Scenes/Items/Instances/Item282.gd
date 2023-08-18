# Lucky Gem
extends Item


var cb_stun: BuffType
var boekie_gem_slow: BuffType
var boekie_gem_armor: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Luck![/color]\n"
	text += "The carrier of this item has a 20% attackspeed adjusted chance to get a random effect on damage:\n"
	text += " Gain 1 experience\n"
	text += " Gain 10 gold\n"
	text += " Stun for 0.5 seconds\n"
	text += " Slow by 10% for 3 seconds\n"
	text += " Decrease armor by 5 for 3 seconds\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	cb_stun = CbStun.new("cb_stun", 0, 0, false, self)
	
	var m: Modifier = Modifier.new()
	var k: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	boekie_gem_slow = BuffType.new("boekie_gem_slow", 0, 0, false, self)
	boekie_gem_slow.set_buff_icon("@@0@@")
	boekie_gem_slow.set_buff_modifier(m)
	boekie_gem_slow.set_stacking_group("boekie_gem_slow")
	boekie_gem_slow.set_buff_tooltip("Gem Slow\nThis is affected by Gem Slow; it has reduced movement speed.")

	k.add_modification(Modification.Type.MOD_ARMOR, 0, -1)
	boekie_gem_armor = BuffType.new("boekie_gem_armor", 0, 0, false, self)
	boekie_gem_armor.set_buff_icon("@@1@@")
	boekie_gem_armor.set_buff_modifier(k)
	boekie_gem_armor.set_stacking_group("boekie_gem_armor")
	boekie_gem_armor.set_buff_tooltip("Gem Armor\nThis is affected by Gem Armor; it has reduced armor.")


func on_damage(event: Event):
	var itm: Item = self
	var target: Unit = event.get_target()
	var a: int = randi_range(0, 4)
	var tower: Tower = itm.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.20 * speed) && event.is_main_target() == true:
		if a < 1:
			cb_stun.apply_only_timed(tower, target, 0.5)
			tower.get_player().display_small_floating_text("Stun!", tower, 255, 165, 0, 30)
		elif a < 2:
			boekie_gem_slow.apply_custom_timed(tower, target, 100, 3)
			tower.get_player().display_small_floating_text("Slow!", tower, 255, 165, 0, 30)
		elif a < 3:
			tower.get_player().give_gold(10, tower, true, true)
			tower.get_player().display_small_floating_text("Gold!", tower, 255, 165, 0, 30)
		elif a < 4:
			tower.add_exp(1.0)
			tower.get_player().display_small_floating_text("Exp!", tower, 255, 165, 0, 30)
		elif a < 5:
			boekie_gem_armor.apply_custom_timed(tower, target, 5, 3)
			tower.get_player().display_small_floating_text("Armor!", tower, 255, 165, 0, 30)
