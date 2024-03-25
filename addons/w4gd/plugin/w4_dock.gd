@tool
extends Control

@export var url := ""
@export var key := ""
@export var profiles := [
	{
		"name": "internal",
		"url": "test",
		"key": "testkey"
	}
]
@export var current_profile := "default"

const COL_BTN = 1
const COL_VALUE = 1
const BTN_LOCK = 0
const BTN_ADD_REMOVE = 1


signal profile_edited(profile: String, key: String, value: String)
signal profile_deleted(profile: String)
signal profile_renamed(profile: String, to: String)
signal profile_added()
signal profile_selected(profile: String)
signal run_confirmed(profile: String, key: String, script_path: String)


func _ready():
	var run_btn := _mk_run_btn()
	run_btn.pressed.connect(_confirm_run)
	var profile_btn := _mk_profile_btn()
	profile_btn.item_selected.connect(_profile_selected)
	var tree := _mk_tree()
	tree.button_clicked.connect(_tree_button_clicked)
	tree.item_edited.connect(_tree_item_edited.bind(tree.get_path()))
	%DeleteConfirm.confirmed.connect(_delete_profile)


func _mk_run_btn() -> Button:
	var script_picker := %ScriptPickerButton as Button
	if has_theme_icon("Script", "EditorIcons"):  # Or it gets saved (broken) since the script is a tool
		script_picker.icon = get_theme_icon("Script", "EditorIcons")
	script_picker.pressed.connect(_pick_file)
	var line_edit := %ScriptLineEdit
	%ScriptPicker.file_selected.connect(func(f): line_edit.text = f)
	%RunConfirm.confirmed.connect(_run_confirmed)
	%RunConfirm.register_text_enter(%ServiceKeyLineEdit)
	return %RunButton


func _mk_profile_btn() -> OptionButton:
	var btn := %ProfilesButton as OptionButton
	btn.clear()
	var idx = 0
	var prof = profiles.duplicate()

	prof.push_front({"name": "default", "url": url, "key": key})

	for p in prof:
		btn.add_item(p["name"])
		btn.set_item_metadata(idx, p["name"])
		if current_profile == p["name"]:
			btn.select(idx)
		idx += 1

	return btn


func _mk_item(root: TreeItem, text: String, val:="") -> TreeItem:
	var it = root.create_child()
	it.set_text(0, text)
	it.set_text(1, val)
	it.set_selectable(0, false)
	return it


func _set_item_meta(item: TreeItem, meta1, meta2):
	item.set_metadata(0, meta1)
	item.set_metadata(1, meta2)


func _mk_tree() -> Tree:
	var tree : Tree = %SettingsTree as Tree
	tree.clear()
	tree.set_column_expand(0, false)
	tree.set_column_clip_content(1, true)
	var root = tree.create_item()
	var prof = profiles.duplicate()
	prof.push_front({"name": "default", "url": url, "key": key})
	for p in prof:
		var k = p["name"]
		var pit := _mk_item(root, " ", k)
		pit.set_icon(0, get_theme_icon("WorldEnvironment", "EditorIcons"))
		_set_item_meta(pit, k, "")
		if k == current_profile:
			pit.set_icon(1, get_theme_icon("ImportCheck", "EditorIcons"))
		pit.add_button(COL_BTN, get_theme_icon("Lock", "EditorIcons"))
		if k == "default":
			pit.add_button(COL_BTN, get_theme_icon("New", "EditorIcons"))
		else:
			pit.add_button(COL_BTN, get_theme_icon("Remove", "EditorIcons"))
		pit.collapsed = k != current_profile
		var tmp
		tmp = _mk_item(pit, "Url", p["url"])
		_set_item_meta(tmp, k, "url")
		tmp = _mk_item(pit, "Key", p["key"])
		_set_item_meta(tmp, k, "key")
	return tree


func _tree_button_clicked(item, column: int, id: int, mouse_button_index: int):
	if item == null:
		return
	var profile = item.get_metadata(0)
	if typeof(profile) != TYPE_STRING:
		return
	if column == COL_BTN:
		if id == BTN_LOCK:
			var childs = item.get_children()
			var was_editable = item.get_first_child().is_editable(1)
			if profile != "default":
				item.set_editable(1, not was_editable)
			for c in childs:
				c.set_editable(1, not was_editable)
			var icon = "Lock" if was_editable else "Unlock"
			item.set_button(COL_BTN, BTN_LOCK, get_theme_icon(icon, "EditorIcons"))
		elif id == BTN_ADD_REMOVE:
			if profile == "default":
				# Adds new profile
				profile_added.emit()
				refresh.call_deferred()
			else:
				# Asks to delete profile
				var confirm := %DeleteConfirm as ConfirmationDialog
				confirm.exclusive = true
				confirm.popup_centered()
				confirm.dialog_text = "Delete profile '%s'?" % [profile]
				confirm.get_cancel_button().grab_focus()
				confirm.set_meta("profile", profile)


func _tree_item_edited(tree_path: NodePath):
	var tree := get_node(tree_path) as Tree
	if tree == null:
		return
	var edited : TreeItem = tree.get_edited()
	var edited_col = tree.get_edited_column()
	if edited == null or edited_col < 0:
		return
	var setting_name = edited.get_metadata(1)
	var value = edited.get_text(edited_col)
	if setting_name == "":
		var profile = edited.get_metadata(0)
		profile_renamed.emit(profile, value)
		edited.set_metadata(0, value)
		_mk_profile_btn()  # Remake button with new names
	else:
		var profile = edited.get_parent().get_metadata(0)
		profile_edited.emit(profile, setting_name, value)


func _delete_profile():
	var profile = %DeleteConfirm.get_meta("profile")
	if typeof(profile) != TYPE_STRING:
		return
	%DeleteConfirm.remove_meta("profile")
	profile_deleted.emit(profile)
	refresh.call_deferred()


func _profile_selected(idx: int):
	var profile = %ProfilesButton.get_item_metadata(idx)
	profile_selected.emit(profile)
	_mk_tree()  # Remake tree to update the tick.


func _pick_file():
	var picker := %ScriptPicker as FileDialog
	picker.clear_filters()
	picker.add_filter("*.gd")
	picker.title = "Select Script"
	picker.exclusive = true
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.popup_centered(Vector2i(500, 400))


func _confirm_run():
	var confirm := (%RunConfirm as ConfirmationDialog)
	var line : String = %ScriptLineEdit.text
	if not FileAccess.file_exists(line):
		_error("Invalid File Name.\nUnable to run '%s'" % line)
		return
	confirm.exclusive = true
	var run_url := url
	for p in profiles:
		if p.name == current_profile:
			run_url = p.url
			break
	%RunConfirmDetails.text = "Profile: '%s'\nURL: '%s'\nPath: '%s'\n" % [current_profile, run_url, line]
	confirm.popup_centered(Vector2(400, 200))
	confirm.get_cancel_button().grab_focus()


func _run_confirmed():
	var key = %ServiceKeyLineEdit.text
	var script_path = %ScriptLineEdit.text
	if key.is_empty():
		_error("Cannot run script with empty service key.")
		return
	run_confirmed.emit(current_profile, key.strip_edges(), script_path)


func _error(message, min_size:=Vector2i(300, 100)):
	%ErrorDialog.dialog_text = message
	%ErrorDialog.exclusive = true
	%ErrorDialog.popup_centered(min_size)


func refresh():
	_mk_tree()
	_mk_profile_btn()
