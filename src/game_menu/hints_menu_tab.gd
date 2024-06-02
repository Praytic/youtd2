class_name HintsMenuTab extends VBoxContainer


signal closed()

enum CsvProperty {
	TITLE,
	TEXT,
}

var _title_list: Array[String] = []
var _text_list: Array[String] = []

@export var csv_path: String
@export var _tree: Tree
@export var _hints_text_label: RichTextLabel

var _properties: Dictionary = {}


#########################
###     Built-in      ###
#########################

func _ready():
	UtilsStatic.load_csv_properties_with_automatic_ids(csv_path, _properties)
	
	var root: TreeItem = _tree.create_item()

	var id_list: Array = _properties.keys()
	id_list.sort()
	
	for id in id_list:
		var displayed_index: int = id + 1
		var entry: Dictionary = _properties[id]
		var title: String = entry[CsvProperty.TITLE]
		var text: String = entry[CsvProperty.TEXT]
		
		var tree_item_text: String = "%d. %s" % [displayed_index, title]
		var child: TreeItem = _tree.create_item(root)
		child.set_text(0, tree_item_text)
		
		_title_list.append(title)
		_text_list.append(text)
	
	var first_item: TreeItem = root.get_child(0)
	_tree.set_selected(first_item, 0)


#########################
###     Callbacks     ###
#########################

func _on_tree_item_selected():
	var selected_item: TreeItem = _tree.get_selected()
	var index: int = selected_item.get_index()
	var title: String = _title_list[index]
	var text: String = _text_list[index]
	text = RichTexts.add_color_to_numbers(text)
	
	var combined_text: String = "[center][color=GOLD]%s[/color][/center]\n \n%s" % [title, text]

	_hints_text_label.clear()
	_hints_text_label.append_text(combined_text)


func _on_close_button_pressed():
	closed.emit()
