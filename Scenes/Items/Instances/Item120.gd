# Purifying Gloves
extends Item


var drol_chainCast: Cast
var cb_stun: BuffType


func get_extra_tooltip_text() -> String:
	var text: String = ""

	text += "[color=GOLD]Purify[/color]\n"
	text += "Grants the carrier a 12.5% attackspeed adjusted chance on attack to cast a purifying beam of magic. Deals 250 spelldamage on the first target and bounces to 2 other targets. Each bounce reduces the damage by 25%. Undead and Orc creeps also get stunned for 0.5 seconds when hit by this beam.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)


func drol_chainStun(event: Event, d: DummyUnit):
	var creep: Unit = event.get_target()

	if creep.get_category() == 0 || creep.get_category() == 3:
		cb_stun.apply_only_timed(d.get_caster(), event.get_target(), 0.5)


func item_init():
	cb_stun = CbStun.new("item_120_stun", 0, 0, false, self)
	
	var m: Modifier = Modifier.new()
	m.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.15, 0.0)

	drol_chainCast = Cast.new("@@0@@", "chainlightning", 5.0)
	drol_chainCast.set_damage_event(drol_chainStun)
	drol_chainCast.data.chain_lightning.damage = 250
	drol_chainCast.data.chain_lightning.damage_reduction = 0.25
	drol_chainCast.data.chain_lightning.chain_count = 3


func on_attack(event: Event):
	var itm: Item = self

	var tower: Tower = itm.get_carrier()
	var speed: float = tower.get_base_attack_speed()

	if tower.calc_chance(0.125 * speed):
		drol_chainCast.target_cast_from_caster(tower, event.get_target(), 1, tower.calc_spell_crit_no_bonus())
