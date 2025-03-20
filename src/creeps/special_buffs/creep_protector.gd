class_name CreepProtector extends BuffType


# NOTE: this doesn't 100% match original code logic but end
# result is the same. Used autocast so that channeling is
# affected by silence.


const PROTECTOR_RANGE: int = 1000


var aura_bt: BuffType
var channel_bt: BuffType
var curse_bt: BuffType


func _init(parent: Node):
	super("creep_protector", 0, 0, true, parent)

	add_event_on_create(on_create)
	
	channel_bt = BuffType.new("channel_bt", 0, 0, true, self)
	channel_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	channel_bt.set_buff_icon_color(Color.DARK_RED)
	channel_bt.set_buff_tooltip("Protector Channel\nChannels a protector curse.")
	
	curse_bt = BuffType.new("curse_bt", 1.5, 0, false, self
		)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, -1.3, 0.0)
	modifier.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, -2, 0.0)
	curse_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	curse_bt.set_buff_icon_color(Color.DARK_RED)
	curse_bt.set_buff_tooltip("Protector Curse\nReduces attack damage and multicrit.")
	curse_bt.set_buff_modifier(modifier)

	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	aura_bt.add_event_on_death(aura_bt_on_death)
	aura_bt.set_hidden()

	var aura: AuraType = AuraType.make_aura_type(107, self)
	add_aura(aura)


func on_create(event: Event):
	var buff: Buff = event.get_buff()
	var protector: Unit = buff.get_buffed_unit()

	var autocast: Autocast = Autocast.make_from_id(172, self)
	protector.add_autocast(autocast)


func aura_bt_on_death(event: Event):
	var buff: Buff = event.get_buff()
	var protector: Unit = buff.get_caster()

	var channel_buff: Buff = protector.get_buff_of_type(channel_bt)

	var protector_is_channeling: bool = channel_buff != null

	if protector_is_channeling:
		var it: Iterate = Iterate.over_units_in_range_of_caster(protector, TargetType.new(TargetType.CREEPS + TargetType.SIZE_MASS + TargetType.SIZE_NORMAL + TargetType.SIZE_BOSS + TargetType.SIZE_AIR), PROTECTOR_RANGE)
		var non_champion_count: int = it.count()
		var stop_channel: bool = non_champion_count == 0

		if stop_channel:
			channel_buff.remove_buff()
	else:
		var attacker: Unit = event.get_target()
		var new_channel_buff: Buff = channel_bt.apply_to_unit_permanent(protector, protector, 0)
		new_channel_buff.user_int = attacker.get_instance_id()


func on_autocast(event: Event):
	var autocast: Autocast = event.get_autocast_type()
	var protector: Unit = autocast.get_caster()
	var channel_buff: Buff = protector.get_buff_of_type(channel_bt)
	var protector_is_channeling: bool = channel_buff != null

	if !protector_is_channeling:
		return
	
	var cursed_tower_instance_id: int = channel_buff.user_int
	var cursed_tower_object: Object = instance_from_id(cursed_tower_instance_id)

	if cursed_tower_object == null || !Utils.unit_is_valid(cursed_tower_object):
		return

	var cursed_tower: Unit = cursed_tower_object as Unit

	var tower_pos: Vector2 = cursed_tower.get_position_wc3_2d()
	var protector_pos: Vector2 = protector.get_position_wc3_2d()
	var cursed_tower_is_in_range: bool = VectorUtils.in_range(tower_pos, protector_pos, PROTECTOR_RANGE)

	if !cursed_tower_is_in_range:
		channel_buff.remove_buff()

		return

	curse_bt.apply(protector, cursed_tower, 0)

	var lightning: InterpolatedSprite = InterpolatedSprite.create_from_unit_to_unit(InterpolatedSprite.LIGHTNING, protector, cursed_tower)
	lightning.modulate = Color.DARK_OLIVE_GREEN
	lightning.set_lifetime(1.0)
