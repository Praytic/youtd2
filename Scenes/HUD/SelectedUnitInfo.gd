extends Control

@onready var _label: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel


func _process(_delta: float):
	_label.clear()

	var selected_unit: Unit = SelectUnit.get_selected_unit()

	if selected_unit == null:
		set_visible(false)

		return

	set_visible(true)

	var label_text: String = ""

	var display_name: String = selected_unit.get_display_name()
	var health: int = floor(selected_unit.get_health())
	var overall_health: int = floor(selected_unit.get_overall_health())
	var mana: int = floor(selected_unit.get_mana())
	var overall_mana: int = floor(selected_unit.get_overall_mana())

	label_text += "[b]%s[/b]\n" % [display_name]
	if overall_health > 0:
		label_text += "Health: %d/%d\n" % [health, overall_health]
	if overall_mana > 0:
		label_text += "Mana: %d/%d\n" % [mana, overall_mana]
	label_text += "Status:"

	_label.append_text(label_text)
