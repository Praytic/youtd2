@tool
extends Control

const SupabaseClient = preload("res://addons/w4gd/supabase/client.gd")

const EXPORT_PRESETS_PATH = 'res://export_presets.cfg'

const EXPORT_OUTPUT_PATH = 'res://.godot/w4cloud/export'
const EXPORT_ZIP_PATH = 'res://.godot/w4cloud/export.zip'

const GAMESERVER_BUCKET = 'gameservers'

@onready var service_key_dialog: ConfirmationDialog = %ServiceKeyDialog
@onready var service_key_field: LineEdit = %ServiceKeyField

@onready var upload_dialog: ConfirmationDialog = %UploadDialog
@onready var export_preset_field: OptionButton = %ExportPresetField
@onready var build_name_field: LineEdit = %BuildNameField
@onready var debug_build_field: CheckBox = %DebugBuildField
@onready var fleet_field: OptionButton = %FleetField

@onready var error_dialog: AcceptDialog = %ErrorDialog
@onready var error_message: Label = %ErrorMessage
@onready var error_details: TextEdit = %ErrorDetails

@onready var progress_window: Window = %ProgressWindow
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_message: Label = %ProgressMessage

var _profile: Dictionary
var _client: SupabaseClient

func _ready():
	service_key_dialog.visible = false
	upload_dialog.visible = false
	error_dialog.visible = false
	progress_window.visible = false

func show_server_uploader(p_profile: Dictionary) -> void:
	if _profile.hash() != p_profile.hash():
		_profile = p_profile
		_client = null

		service_key_field.text = ''
		service_key_dialog.popup_centered(Vector2i(500, 50))
	else:
		_show_upload_dialog()

func _show_progress(p_amount: float, p_msg: String = "") -> void:
	progress_bar.value = p_amount

	progress_message.visible = not p_msg.is_empty()
	progress_message.text = p_msg

	progress_window.popup_centered(Vector2i(600, 100))

func _hide_progress() -> void:
	progress_window.visible = false

func _show_error(p_msg: String, p_details: String = "") -> void:
	_hide_progress()

	error_message.text = p_msg

	error_details.visible = not p_details.is_empty()
	error_details.text = p_details

	push_error(p_msg, p_details)
	error_dialog.popup_centered(Vector2i(600, 50 if p_details.is_empty() else 400))

func _on_service_key_dialog_confirmed() -> void:
	_client = SupabaseClient.new(self, _profile['url'], service_key_field.text)

	# @todo Need a simpler way to ping Supabase and test our creds.
	var result = await _client.auth.admin.get_users().async()
	if result.is_error():
		print(result)
		_profile.clear()
		_show_error("Unable to connect to W4 Cloud with the given service key")
		return

	_show_upload_dialog()

func _show_upload_dialog() -> void:
	_update_export_presets()
	_update_fleet_options()

	upload_dialog.popup_centered(Vector2i(400, 200))

func _update_export_presets() -> void:
	export_preset_field.clear()

	var file := ConfigFile.new()
	if file.load(EXPORT_PRESETS_PATH) != OK:
		return

	var presets := []
	for section in file.get_sections():
		if not file.has_section_key(section, 'name'):
			continue
		if file.get_value(section, 'platform') != 'Linux/X11':
			continue

		presets.push_back({
			name = file.get_value(section, 'name'),
			dedicated_server = file.get_value(section, 'dedicated_server', false),
		})

	presets.sort_custom(func (a, b):
		if a['dedicated_server'] == b['dedicated_server']:
			return a['name'].nocasecmp_to(b['name']) <= 0
		return a['dedicated_server']
	)

	for preset in presets:
		export_preset_field.add_item(preset['name'])

func _update_fleet_options() -> void:
	fleet_field.clear()
	fleet_field.add_item("- Don't update any fleet -", 0)
	fleet_field.set_item_metadata(0, {})
	fleet_field.selected = 0

	var result = await _client.rest.GET("/fleet", {}, {'Accept-Profile': 'w4online'}).async()
	if result.is_error():
		print ("Error getting fleets: ", result)
		return

	var i := 1
	for fleet in result.as_array():
		fleet_field.add_item(fleet['description'], i)
		fleet_field.set_item_metadata(i, fleet)
		i += 1

static func _remove_directory(p_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(p_path):
		return true

	var dir := DirAccess.open(p_path)
	if not dir:
		return false

	dir.list_dir_begin()
	var fn = dir.get_next()
	while fn != '':
		if dir.current_is_dir():
			if fn != '.' and fn != '..':
				if not _remove_directory(p_path + '/' + fn):
					return false
		else:
			if dir.remove(fn) != OK:
				return false
		fn = dir.get_next()
	dir.list_dir_end()

	if DirAccess.remove_absolute(p_path) != OK:
		return false

	return true

static func _is_dir_empty(p_path: String) -> bool:
	var count := 0

	var dir := DirAccess.open(p_path)
	if not dir:
		return true

	dir.list_dir_begin()
	var fn = dir.get_next()
	while fn != '':
		if fn != '.' and fn != '..':
			count += 1
		fn = dir.get_next()
	dir.list_dir_end()

	return count == 0

static func _add_dir_to_zip(p_zip: ZIPPacker, p_path: String, p_parents: Array = []) -> bool:
	var dir := DirAccess.open(p_path)
	if not dir:
		return false

	dir.list_dir_begin()
	var fn = dir.get_next()
	while fn != '':
		if dir.current_is_dir():
			if fn != '.' and fn != '..':
				if not _add_dir_to_zip(p_zip, p_path + '/' + fn, p_parents + [fn]):
					return false
		else:
			if p_zip.start_file(fn if p_parents.is_empty() else "/".join(p_parents) + "/" + fn) != OK:
				return false

			var file := FileAccess.open(p_path + "/" + fn, FileAccess.READ)
			if not file:
				return false

			while not file.eof_reached():
				var buffer = file.get_buffer(4096)
				if p_zip.write_file(buffer) != OK:
					return false

			if p_zip.close_file() != OK:
				return false

		fn = dir.get_next()
	dir.list_dir_end()

	return true

func _prepare_export_paths() -> bool:
	if not _clean_export_paths():
		return false

	if DirAccess.make_dir_recursive_absolute(EXPORT_OUTPUT_PATH) != OK:
		return false

	return true

func _clean_export_paths() -> bool:
	if DirAccess.dir_exists_absolute(EXPORT_OUTPUT_PATH):
		if not _remove_directory(EXPORT_OUTPUT_PATH):
			return false

	if FileAccess.file_exists(EXPORT_ZIP_PATH):
		if DirAccess.remove_absolute(EXPORT_ZIP_PATH) != OK:
			return false

	return true

func _on_upload_dialog_confirmed() -> void:
	if export_preset_field.get_selected_id() == -1:
		_show_error("Must select an existing Linux export preset.")
		return

	var export_preset := export_preset_field.get_item_text(export_preset_field.get_selected_id())
	var export_debug := debug_build_field.button_pressed

	var build_name := build_name_field.text.strip_edges()
	if build_name == '':
		_show_error("Must enter a valid build name.")
		return

	var fleet: Dictionary = fleet_field.get_selected_metadata()

	if ! await _do_export(export_preset, export_debug):
		_clean_export_paths()
		return

	if ! await _do_zip():
		_clean_export_paths()
		return

	if ! await _do_upload_and_create_build(build_name, fleet):
		_clean_export_paths()
		return

	_clean_export_paths()
	_hide_progress()

func _do_export(p_export_preset: String, p_debug: bool) -> bool:
	_show_progress(0, "Preparing to export...")
	await get_tree().process_frame

	if ! _prepare_export_paths():
		_show_error("Unable to prepare export paths")
		return false

	_show_progress(25, "Exporting... This may take awhile!")
	await get_tree().process_frame

	# Convert from the 'res://' path to an absolute path.
	var absolute_export_path = ProjectSettings.globalize_path(EXPORT_OUTPUT_PATH + "/game.x86_64")

	var args = [
		'--headless',
		'--export-debug' if p_debug else '--export-release',
		p_export_preset,
		absolute_export_path,
	]

	var output = []
	var exit_code = OS.execute(OS.get_executable_path(), args, output, true)

	if exit_code != 0 or _is_dir_empty(EXPORT_OUTPUT_PATH):
		_show_error("Error exporting project:", "\n".join(output))
		return false

	return true

func _do_zip() -> bool:
	_show_progress(50, "Creating zip file... This may take awhile!")
	await get_tree().process_frame

	var zip := ZIPPacker.new()
	if zip.open(EXPORT_ZIP_PATH) != OK:
		_show_error("Unable to open ZIP file for writing")
		return false

	if not _add_dir_to_zip(zip, EXPORT_OUTPUT_PATH):
		_show_error("Unable to add exported files to ZIP file")
		return false

	if zip.close() != OK:
		_show_error("Unable to close ZIP file")
		return false

	return true

func _do_upload_and_create_build(p_build_name: String, p_fleet: Dictionary) -> bool:
	var zip_data = FileAccess.get_file_as_bytes(EXPORT_ZIP_PATH)
	if zip_data.size() == 0:
		_show_error("Unable to load ZIP file into memory")
		return false

	var result

	_show_progress(75, "Uploading ZIP file to W4 Cloud... This may take awhile!")

	result = await _client.storage.list_buckets().async()
	if result.is_error():
		_show_error("Unable to list storage buckets: " + str(result))
		return false

	# Ensure the destination bucket exists.
	if not GAMESERVER_BUCKET in result.as_array().map(func (x): return x['name']):
		result = await _client.storage.create_bucket(GAMESERVER_BUCKET).async()
		if result.is_error():
			_show_error("Unable to create storage bucket: " + str(result))
			return false

	result = await _client.storage.upload_object(GAMESERVER_BUCKET, p_build_name.uri_encode() + '.zip', zip_data).async()
	if result.is_error():
		_show_error("Unable to upload ZIP file: " + str(result))
		return false

	_show_progress(95, "Creating the new build in the database...")

	var data := {
		object_key = GAMESERVER_BUCKET + "/" + p_build_name + '.zip',
		name = p_build_name,
		props = {},
	}
	result = await _client.rest.rpc("w4online.gameserver_build_create", data).async()
	if result.is_error():
		_show_error("Unable to create build in the database: " + str(result))
		return false

	if not p_fleet.is_empty():
		var fleet = p_fleet.duplicate(true)
		fleet.erase('cluster')
		fleet.erase('deleted')

		fleet['build_id'] = result.build_id
		fleet['image'] = null

		result = await _client.rest.rpc("w4online.fleet_update", fleet).async()
		if result.is_error():
			_show_error("Unable to update fleet: " + str(result))
			return false

	return true
