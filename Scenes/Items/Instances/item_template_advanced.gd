# Template Item Advanced
extends Item

# NOTE: not a real item script, used as a template for item
# scripts. Use for advanced items that have special effects.


# func get_extra_tooltip_text() -> String:
# 	var text: String = ""

# 	text += "[color=GOLD]Title[/color]\n"
# 	text += "Description\n"
# 	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"

# 	return text


# func get_autocast_description() -> String:
# 	var text: String = ""

# 	text += "Description"
# 	text += " \n"
# 	text += "[color=ORANGE]Level Bonus:[/color]\n"
# 	text += "foo\n"
# 	text += "bar\n"

# 	return text


# func load_triggers(triggers: BuffType):
# 	triggers.add_event_on_damage(on_damage)
# 	triggers.add_periodic_event(periodic, 5)


# func load_modifier(modifier: Modifier):
# 	modifier.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)


# func item_init():
# 	var m: Modifier = Modifier.new()
# 	m.add_modification(Modification.Type.MOD_ARMOR, 0.0, 0.0)
# 	example_buff = BuffType.new("example_buff", 5, 0, true, self)
# 	example_buff.set_buff_icon("@@0@@")
# 	example_buff.set_buff_modifier(m)
# 	example_buff.set_stacking_group("example_buff")
# 	example_buff.set_buff_tooltip("Title\nDescription.")

# 	var autocast: Autocast = Autocast.make()
#	autocast.title = "Title"
#	autocast.description = get_autocast_description()
#	autocast.icon = "res://Resources/Textures/gold.tres"
# 	autocast.caster_art = ""
# 	autocast.target_art = ""
# 	autocast.num_buffs_before_idle = 0
# 	autocast.autocast_type = Autocast.Type.AC_TYPE_ALWAYS_BUFF
# 	autocast.target_self = true
# 	autocast.cooldown = 15
# 	autocast.is_extended = false
# 	autocast.mana_cost = 0
# 	autocast.buff_type = null
# 	autocast.target_type = TargetType.new(TargetType.TOWERS)
# 	autocast.cast_range = 200
# 	autocast.auto_range = 200
# 	autocast.handler = on_autocast
# 	set_autocast(autocast)

# 	var aura: AuraType = AuraType.new()
# 	aura.aura_range = 200
# 	aura.target_type = TargetType.new(TargetType.TOWERS)
# 	aura.target_self = true
# 	aura.level = 0
# 	aura.level_add = 1
# 	aura.power = 0
# 	aura.power_add = 1
# 	aura.aura_effect = aura_effect
# 	add_aura(aura)


# func on_damage(event: Event):
# 	var itm: Item = self


# func on_autocast(event: Event):
# 	var itm: Item = self
