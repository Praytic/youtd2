extends ItemBehavior


var stun_bt: BuffType
var slow_bt: BuffType
var armor_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func item_init():
	stun_bt = CbStun.new("stun_bt", 0, 0, false, self)
	
	slow_bt = BuffType.new("slow_bt", 0, 0, false, self)
	slow_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	slow_bt.set_buff_tooltip(tr("KRA1"))
	var slow_bt_mod: Modifier = Modifier.new()
	slow_bt_mod.add_modification(Modification.Type.MOD_MOVESPEED, 0, -0.001)
	slow_bt.set_buff_modifier(slow_bt_mod)

	armor_bt = BuffType.new("armor_bt", 0, 0, false, self)
	armor_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	armor_bt.set_buff_tooltip(tr("PJYW"))
	var armor_bt_mod: Modifier = Modifier.new()
	armor_bt_mod.add_modification(Modification.Type.MOD_ARMOR, 0, -1)
	armor_bt.set_buff_modifier(armor_bt_mod)


func on_damage(event: Event):
	var target: Unit = event.get_target()
	var a: int = Globals.synced_rng.randi_range(0, 4)
	var tower: Tower = item.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.20 * speed) && event.is_main_target() == true:
		
		if a < 1:
			CombatLog.log_item_ability(item, null, "Stun!")
			stun_bt.apply_only_timed(tower, target, 0.5)
			tower.get_player().display_small_floating_text("Stun!", tower, Color8(255, 165, 0), 30)
		elif a < 2:
			CombatLog.log_item_ability(item, null, "Slow!")
			slow_bt.apply_custom_timed(tower, target, 100, 3)
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
			armor_bt.apply_custom_timed(tower, target, 5, 3)
			tower.get_player().display_small_floating_text("Armor!", tower, Color8(255, 165, 0), 30)
