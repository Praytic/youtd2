extends Tower


var sternbogen_holy_buff: BuffType
var magical_sight: BuffType


# NOTE: mod_value and mod_value_add are multiplied by 1000,
# leaving as in original
func get_tier_stats() -> Dictionary:
	return {
		1: {magical_sight_range = 650, mod_value = 50, mod_value_add = 2, duration = 3, duration_add = 0.12},
		2: {magical_sight_range = 700, mod_value = 100, mod_value_add = 4, duration = 3, duration_add = 0.16},
		3: {magical_sight_range = 750, mod_value = 150, mod_value_add = 6, duration = 4, duration_add = 0.16},
		4: {magical_sight_range = 800, mod_value = 200, mod_value_add = 8, duration = 4, duration_add = 0.20},
		5: {magical_sight_range = 850, mod_value = 300, mod_value_add = 10, duration = 5, duration_add = 0.20},
	}


func get_extra_tooltip_text() -> String:
	var magical_sight_range: String = String.num(_stats.magical_sight_range, 2)
	var duration: String = String.num(_stats.duration, 2)
	var mod_value: String = String.num(_stats.mod_value / 10, 2)
	var duration_add: String = String.num(_stats.duration_add, 2)
	var mod_value_add: String = String.num(_stats.mod_value_add / 10.0, 2)

	var text: String = ""

	text += "[color=GOLD]Magical Sight[/color]\n"
	text += "Can see invisible enemy units in %s range.\n" % magical_sight_range
	text += "[color=GOLD]Power of Light[/color]\n"
	text += "The mighty holy light weakens enemy undead creeps for %s seconds, so they will receive %s%% more damage from physical and spell attacks.\n" % [duration, mod_value]
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds\n" % duration_add
	text += "+%s%% damage" % mod_value_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(_modifier: Modifier):
	magical_sight = MagicalSightBuff.new("holy_light_magical_sight", _stats.magical_sight_range, self)
	magical_sight.apply_to_unit_permanent(self, self, 0)


func tower_init():
	var light_mod: Modifier = Modifier.new()
	sternbogen_holy_buff = BuffType.new("sternbogen_holy_buff", 0.0, 0.0, false, self)
	light_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.0, 0.001)
	light_mod.add_modification(Modification.Type.MOD_ATK_DAMAGE_RECEIVED, 0.0, 0.001)
	sternbogen_holy_buff.set_buff_modifier(light_mod)
	sternbogen_holy_buff.set_buff_icon("@@1@@")
	sternbogen_holy_buff.set_buff_tooltip("Holy Weakness\nThis unit has Holy Weakness; it will receive more damage from attacks and spells.")


func on_damage(event: Event):
	var tower = self

	var creep = event.get_target()
#	0.001 Basic Bonus
	var bufflevel: int = _stats.mod_value + _stats.mod_value_add * tower.get_level()
	if (CreepCategory.enm.UNDEAD == creep.get_category()):
		sternbogen_holy_buff.apply_custom_timed(tower, event.get_target(), bufflevel, _stats.duration + _stats.duration_add * tower.get_level())
