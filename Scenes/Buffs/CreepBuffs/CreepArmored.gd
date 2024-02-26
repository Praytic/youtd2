class_name CreepArmored extends BuffType


func _init(parent: Node):
	super("creep_armored", 0, 0, true, parent)
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_ARMOR, 10, 0.0)
	modifier.add_modification(Modification.Type.MOD_ARMOR_PERC, 0.4, 0.0)
	set_buff_modifier(modifier)
	
	var icon_name = get_script().resource_path.get_file().trim_suffix(".gd")
	icon_name = Utils.camel_to_snake(icon_name)
	var icon_path = "res://Resources/Textures/UI/Icons/CreepBuffs/%s.tres" % icon_name
	set_buff_icon(icon_path)
