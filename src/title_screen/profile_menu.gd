extends PanelContainer


signal close_pressed()


var _setup_error_list: Array[String] = []

var _regex_allowed_chars: RegEx


@export var _name_edit: LineEdit
@export var _export_exp_menu: ExportExpMenu
@export var _import_exp_menu: ImportExpMenu
@export var _level_label: Label
@export var _exp_label: Label
@export var _exp_for_next_lvl_left_label: Label
@export var _exp_for_next_lvl_label: Label
@export var _wisdom_upgrade_menu: WisdomUpgradeMenu


#########################
###     Built-in      ###
#########################

func _ready():
	_regex_allowed_chars = RegEx.new()
	_regex_allowed_chars.compile(Constants.PLAYER_NAME_ALLOWED_CHARS)

	var player_name: String = Settings.get_setting(Settings.PLAYER_NAME)
	_name_edit.text = player_name
	
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)
	var player_exp: int = ExperiencePassword.decode(exp_password)
	
	var player_exp_is_valid: bool = player_exp != -1
	if !player_exp_is_valid:
		_setup_error_list.append("Exp password loaded from settings is invalid. Defaulting to 0 experience.")
		
		player_exp = 0
	
	_load_player_exp(player_exp)


#########################
###      Private      ###
#########################

func _load_player_exp(player_exp: int):
	_exp_label.text = str(player_exp)

	var player_level: int = PlayerExperience.get_level_at_exp(player_exp)
	_level_label.text = str(player_level)
	
	var reached_max_level: bool = player_level == Constants.PLAYER_MAX_LEVEL
	
	_exp_for_next_lvl_left_label.visible = !reached_max_level
	_exp_for_next_lvl_label.visible = !reached_max_level
	
	if !reached_max_level:
		var next_lvl: int = player_level + 1
		var exp_for_next_lvl: int = PlayerExperience.get_exp_for_level(next_lvl)
		_exp_for_next_lvl_label.text = str(exp_for_next_lvl)


#########################
###     Callbacks     ###
#########################

func _on_name_edit_text_changed(new_text: String):
	var old_caret_column: int = _name_edit.get_caret_column()

	var regexed_text: String = ""
	for valid_character in _regex_allowed_chars.search_all(new_text):
		regexed_text += valid_character.get_string()
	
	_name_edit.set_text(regexed_text)

	_name_edit.set_caret_column(old_caret_column)


# NOTE: update display_name for account only when profile
# menu is closed, not every time when name edit text
# changes. This is to avoid too frequent updates.
func _on_close_button_pressed():
	var player_name: String = _name_edit.get_text()

	var name_is_too_short: bool = player_name.length() < Constants.PLAYER_NAME_LENGTH_MIN
	if name_is_too_short:
		Utils.show_popup_message(self, "Error", "Player name is too short.")

		return

	close_pressed.emit()

	Settings.set_setting(Settings.PLAYER_NAME, player_name)
	Settings.flush()

	var running_on_desktop: bool = OS.has_feature("pc")
	var connected_to_server: bool = NakamaConnection.get_state() == NakamaConnection.State.CONNECTED
	if running_on_desktop && connected_to_server:
		_update_player_name_for_nakama_account()


func _update_player_name_for_nakama_account():
	var client: NakamaClient = NakamaConnection.get_client()
	var session: NakamaSession = NakamaConnection.get_session()
	var username = null
	var display_name: String = _name_edit.get_text()
	var avatar_url = null
	var lang_tag = null
	var location = null
	var timezone = null
	var update_account_async_result: NakamaAsyncResult = await client.update_account_async(session, username, display_name, avatar_url, lang_tag, location, timezone)

	if update_account_async_result.is_exception():
		push_error("Error in update_account_async(): %s" % update_account_async_result)
		
		return


func _on_import_exp_button_pressed():
	_import_exp_menu.show()


func _on_export_exp_button_pressed():
	var exp_password: String = Settings.get_setting(Settings.EXP_PASSWORD)

#	NOTE: if password in settings is empty, generate a
#	password for 0 exp so that there's something to show in
#	export menu.
	if exp_password.is_empty():
		exp_password = ExperiencePassword.encode(0)

	_export_exp_menu.set_exp_password(exp_password)
	_export_exp_menu.show()


func _on_import_exp_menu_import_pressed():
	var exp_password: String = _import_exp_menu.get_exp_password()
	var player_exp: int = ExperiencePassword.decode(exp_password)

#	NOTE: treat empty password as invalid to prevent player
#	from accidentally resetting exp to 0.
	var player_level_is_valid: bool = player_exp != -1 && !exp_password.is_empty()
	if !player_level_is_valid:
		Utils.show_popup_message(self, "Error", "Experience password is invalid.\n")
		
		return
	
	Settings.set_setting(Settings.EXP_PASSWORD, exp_password)
	Settings.flush()

	var success_message: String = "Successfully imported experience password. You now have [color=GOLD]%d[/color] experience!" % player_exp
	Utils.show_popup_message(self, "Success", success_message)
	_load_player_exp(player_exp)

#	NOTE: need to update wisdom upgrades because they depend
#	on player exp
	_wisdom_upgrade_menu.load_wisdom_upgrades_from_settings()


func _on_visibility_changed():
	if visible:
		_wisdom_upgrade_menu.load_wisdom_upgrades_from_settings()
		
		if !_setup_error_list.is_empty():
			for error in _setup_error_list:
				Utils.show_popup_message(self, "Error", error)

			_setup_error_list.clear()
