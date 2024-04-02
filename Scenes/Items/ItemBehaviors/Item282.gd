# Lucky Gem
extends ItemBehavior


var cb_stun: BuffType
var boekie_gem_slow_bt: BuffType
var boekie_gem_armor_bt: BuffType


func get_ability_description() -> String:
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
	cb_stun = CbStun.new("item_282_stun", 0, 0, false, self)
	
	boekie_gem_slow_bt = BuffType.new("boekie_gem_slow_bt", 0, 0, false, self)
	boekie_gem_slow_bt.set_buff_icon("foot.tres")
	boekie_gem_slow_bt.set_buff_tooltip("Gem Slow\nReduces movement speed.")
	boekie_gem_slow_bt.set_stacking_group("boekie_gem_slow_bt")
	var boekie_gem_slow_bt_mod: Modifier = Modifier.new()
	boekie_gem_slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	boekie_gem_slow_bt.set_buff_modifier(boekie_gem_slow_bt_mod)

	boekie_gem_armor_bt = BuffType.new("boekie_gem_armor_bt", 0, 0, false, self)
	boekie_gem_armor_bt.set_buff_icon("shield.tres")
	boekie_gem_armor_bt.set_buff_tooltip("Gem Armor\nReduces armor.")
	boekie_gem_armor_bt.set_stacking_group("boekie_gem_armor_bt")
	var boekie_gem_armor_bt_mod: Modifier = Modifier.new()
	boekie_gem_armor_bt_mod.add_modification(Modification.Type.MOD_ARMOR, 0, -1)
	boekie_gem_armor_bt.set_buff_modifier(boekie_gem_armor_bt_mod)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var a: int = Globals.synced_rng.randi_range(0, 4)
	var tower: Tower = item.get_carrier()
	var speed: float = tower.get_base_attackspeed()

	if tower.calc_chance(0.20 * speed) && event.is_main_target() == true:
		
		if a < 1:
			CombatLog.log_item_ability(item, null, "Stun!")
			cb_stun.apply_only_timed(tower, target, 0.5)
			tower.get_player().display_small_floating_text("Stun!", tower, Color8(255, 165, 0), 30)
		elif a < 2:
			CombatLog.log_item_ability(item, null, "Slow!")
			boekie_gem_slow_bt.apply_custom_timed(tower, target, 100, 3)
			tower.get_player().display_small_floating_text("Slow!", tower, Color8(255, 165, 0), 30)
		elif a < 3:
			CombatLog.log_item_ability(item, null, "Gold!")
			tower.get_player().give_gold(10, tower, true, true)
			tower.get_player().display_small_floating_text("Gold!", tower, Color8(255, 165, 0), 30)
		elif a < 4:
			CombatLog.log_item_ability(item, null, "Exp!")
			tower.add_exp(1.0)
			tower.get_player().display_small_floating_text("Exp!", tower, Color8(255, 165, 0), 30)
		elif a < 5:
			CombatLog.log_item_ability(item, null, "Armor!")
			boekie_gem_armor_bt.apply_custom_timed(tower, target, 5, 3)
			tower.get_player().display_small_floating_text("Armor!", tower, Color8(255, 165, 0), 30)
