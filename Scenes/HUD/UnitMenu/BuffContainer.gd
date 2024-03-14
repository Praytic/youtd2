class_name BuffContainer extends GridContainer


# Displays buffs of a unit.

# TODO: improve performance. Currently, this script remakes all buffs when buffs change. Save current state and do a diff and add/remove only those buffs which changed.


func load_buffs_for_unit(unit: Unit):
	var friendly_buff_list: Array[Buff] = unit._get_buff_list(true)
	var unfriendly_buff_list: Array[Buff] = unit._get_buff_list(false)

	var buff_list: Array[Buff] = []
	buff_list.append_array(friendly_buff_list)
	buff_list.append_array(unfriendly_buff_list)

	var hidden_buff_list: Array[Buff] = []

	for buff in buff_list:
		if buff.is_hidden():
			hidden_buff_list.append(buff)

	if !Config.show_hidden_buffs():
		for buff in hidden_buff_list:
			buff_list.erase(buff)

	for buff_icon in get_children():
		buff_icon.queue_free()

	for buff in buff_list:
		var tooltip: String = buff.get_tooltip_text()
		var buff_icon: TextureRectWithRichTooltip = TextureRectWithRichTooltip.new()
		buff_icon.set_tooltip_text(tooltip)

		var texture_path: String = buff.get_buff_icon()

		if !ResourceLoader.exists(texture_path):
			if buff.is_hidden():
				texture_path = "res://Assets/Buffs/question_mark.png"
			elif buff.is_friendly():
				texture_path = "res://Assets/Buffs/buff_plus.png"
			else:
				texture_path = "res://Assets/Buffs/buff_minus.png"

		var texture: Texture2D = load(texture_path)
		buff_icon.texture = texture
		add_child(buff_icon)
