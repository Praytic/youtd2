extends Theme
class_name ScalableTheme


const _SCALABLE_CONSTANTS := {
	# Theme constants subject to scaling (by node type).
	# Editor types are not included.
	
	"BoxContainer": [
		"separation"
	],
	"Button": [
		"hseparation"
	],
	"CheckBox": [
		"check_vadjust",
		"hseparation",
	],
	"CheckButton": [
		"check_vadjust",
		"hseparation",
	],
	"ColorPicker": [
		"h_width",
		"label_width",
		"margin",
		"sv_height",
		"sv_width",
	],
	"ColorPickerButton": [
		"hseparation",
	],
	"GridContainer": [
		"hseparation",
		"vseparation",
	],
	"HBoxContainer": [
		"separation",
	],
	"HSeparator": [
		"separation",
	],
	"HSplitContainer": [
		"separation",
	],
	"ItemList": [
		"hseparation",
		"icon_margin",
		"line_separation",
		"vseparation",
	],
	"Label": [
		"line_spacing",
		"shadow_offset_x",
		"shadow_offset_y",
	],
	"LinkButton": [
		"underline_spacing",
	],
	"MarginContainer": [
		"margin_bottom",
		"margin_left",
		"margin_right",
		"margin_top",
	],
	"MenuButton": [
		"hseparation",
	],
	"OptionButton": [
		"arrow_margin",
		"hseparation",
	],
	"PopupMenu": [
		"hseparation",
		"vseparation",
	],
	"RichTextLabel": [
		"line_separation",
		"shadow_offset_x",
		"shadow_offset_y",
		"table_hseparation",
		"table_vseparation",
	],
	"TabContainer": [
		"hseparation",
		"label_valign_bg",
		"label_valign_fg",
		"side_margin",
		"top_margin",
	],
	"Tabs": [
		"hseparation",
		"label_valign_bg",
		"label_valign_fg",
		"top_margin",
	],
	"TextEdit": [
		"line_spacing",
	],
	"ToolButton": [
		"hseparation",
	],
	"TooltipLabel": [
		"shadow_offset_x",
		"shadow_offset_y",
	],
	"Tree": [
		"button_margin",
		"hseparation",
		"item_margin",
		"scroll_border",
		"scroll_speed",
		"vseparation",
	],
	"VBoxContainer": [
		"separation",
	],
	"VSeparator": [
		"separation",
	],
	"VSplitContainer": [
		"separation",
	],
	"WindowDialog": [
		"close_h_ofs",
		"close_v_ofs",
		"scaleborder_size",
		"title_height",
	],
}

const _SCALABLE_FONT_PROPS := {
	# Font properties subject to scaling.
	
	"Button": [
		"font_size",
	],
	"CustomTextureButton": [
		"font_size",
	],
	"GameMessageRichTextLabel": [
		"bold_font_size",
		"bold_italics_font_size",
		"italics_font_size",
		"mono_font_size",
		"normal_font_size",
	],
	"Label": [
		"font_size",
	],
	"RichTextLabel": [
		"bold_font_size",
		"bold_italics_font_size",
		"italics_font_size",
		"mono_font_size",
		"normal_font_size",
	],
}

const _SCALABLE_SBOX_PROPS := {
	# Stylebox properties subject to scaling (by stylebox type).
	
	"StyleBoxEmpty": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
	],
	"StyleBoxLine": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
		"grow_begin",
		"grow_end",
		"thickness",
	],
	"StyleBoxTexture": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
		"expand_margin_left",
		"expand_margin_right",
		"expand_margin_top",
		"expand_margin_bottom",
		"margin_left",
		"margin_right",
		"margin_top",
		"margin_bottom",
		"region_rect",
	],
	"StyleBoxFlat": [
		"content_margin_left",
		"content_margin_right",
		"content_margin_top",
		"content_margin_bottom",
		"expand_margin_left",
		"expand_margin_right",
		"expand_margin_top",
		"expand_margin_bottom",
		"border_width_left",
		"border_width_top",
		"border_width_right",
		"border_width_bottom",
		"corner_radius_top_left",
		"corner_radius_top_right",
		"corner_radius_bottom_right",
		"corner_radius_bottom_left",
		"corner_detail",
		"shadow_size",
		"shadow_offset",
	]
}

var _saved_constants: Dictionary
var _saved_tex_sizes: Dictionary
var _saved_font_props: Dictionary
var _saved_sbox_props: Dictionary


func _init() -> void:
	
#	call_deferred("_subscribe_to_signal")
	
	_saved_constants = _save_constants()
	_saved_tex_sizes = _save_texture_sizes()
	_saved_font_props = _save_font_properties()
	_saved_sbox_props = _save_stylebox_properties()
	
	print("Scalable theme properties were initialized:")
	_print_props(_saved_constants)
	_print_props(_saved_tex_sizes)
	_print_props(_saved_font_props)
	_print_props(_saved_sbox_props)


func _subscribe_to_signal():
	Settings.interface_size_changed.connect(apply_scale)
	apply_scale(Settings.get_setting(Settings.INTERFACE_SIZE))


func _print_props(props: Dictionary):
	for prop_name in props.keys():
		for prop_key in props[prop_name].keys():
			print("%s.%s: %s" % [prop_name, prop_key, props[prop_name][prop_key]])


func apply_scale(factor: float):
#	_scale_constants(factor)
#	_scale_textures(factor)
	_scale_fonts(factor)
#	_scale_styleboxes(factor)


func _save_constants() -> Dictionary:

	var constants := {}

	for item_type in get_constant_type_list():
		if item_type in _SCALABLE_CONSTANTS:
			constants[item_type] = {}
			for const_name in get_constant_list(item_type):
				if const_name in _SCALABLE_CONSTANTS[item_type]:
					var value = get_constant(const_name, item_type)
					if value > 0:
						constants[item_type][const_name] = value

	return constants


func _save_texture_sizes() -> Dictionary:

	var tex_sizes := {}

	for item_type in get_icon_type_list():
		for icon_name in get_icon_list(item_type):
			var icon := get_icon(icon_name, item_type)
			if (icon is ImageTexture) and (not icon in tex_sizes) and (icon.size != Vector2.ZERO):
				tex_sizes[icon] = icon.size

	for item_type in get_stylebox_type_list():
		for sbox_name in get_stylebox_list(item_type):
			var sbox = get_stylebox(sbox_name, item_type)
			if sbox is StyleBoxTexture:
				var texture = sbox.texture
				if (texture is ImageTexture) and (not texture in tex_sizes) and (texture.size != Vector2.ZERO):
					tex_sizes[texture] = texture.size

	return tex_sizes


func _save_font_properties() -> Dictionary:

	var font_props := {}

	for item_type in get_font_size_type_list():
		for font_name in get_font_size_list(item_type):
			var font_size := get_font_size(font_name, item_type)
			if (not font_props.has(item_type)) and (font_name in _SCALABLE_FONT_PROPS.get(item_type, {})):
				font_props[item_type] = {}
			font_props[item_type][font_name] = font_size

	return font_props


func _save_stylebox_properties() -> Dictionary:

	var sbox_props := {}

	for item_type in get_stylebox_type_list():
		for sbox_name in get_stylebox_list(item_type):
			var sbox = get_stylebox(sbox_name, item_type)

			if not sbox in sbox_props:
				sbox_props[sbox] = {}

			var sbox_type = sbox.get_class()
			for prop in _SCALABLE_SBOX_PROPS[sbox_type]:

				if not prop in sbox:
					continue
				var value = sbox.get(prop)
				var discard := false

				match typeof(value):
					TYPE_VECTOR2:
						# Special case for shadow_offset
						if value == Vector2.ZERO:
							discard = true
					TYPE_RECT2:
						# Special case for region_rect
						if not value.has_area():
							discard = true
					_:
						if value <= 0:
							discard = true

				if not discard:
					sbox_props[sbox][prop] = value


	return sbox_props


func _scale_constants(factor: float) -> void:

	for item_type in _saved_constants:
		for const_name in _saved_constants[item_type]:
			var new_value = _saved_constants[item_type][const_name] * factor
			new_value = max(1, new_value)
			set_constant(const_name, item_type, new_value)


func _scale_textures(factor: float) -> void:

	for texture in _saved_tex_sizes:
		texture.size = _saved_tex_sizes[texture] * factor


func _scale_fonts(factor: float) -> void:

	for font in _saved_font_props:
		for prop in _saved_font_props[font]:
			var new_value = _saved_font_props[font][prop] * factor
			new_value = max(1, new_value)
			set_font_size(prop, font, new_value)


func _scale_styleboxes(factor: float) -> void:

	for sbox in _saved_sbox_props:
		for prop in _saved_sbox_props[sbox]:
			var value = _saved_sbox_props[sbox][prop]
			var new_value
			match typeof(value):
				TYPE_RECT2:
					# Special case for region_rect
					new_value = Rect2(value.position * factor, value.size * factor)
				TYPE_VECTOR2:
					# Special case for shadow_offset
					new_value = value * factor
				_:
					new_value = value * factor
					new_value = max(1, new_value)
			sbox.set(prop, new_value)


