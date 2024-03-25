extends Node

class Profile:
	var id: StringName
	var username: String

	static func _w4rm_type_options(opts) -> void:
		opts["id"] = W4RM.tref("auth.users", {
			default = "auth.uid()",
			external = true,
		})

	static func _w4rm_security_policies(policies) -> void:
		policies["Anyone can view profiles"] = W4RM.build_security_policy_for(['anon', 'authenticated']).can_select();
		policies["User can create own profile"] = W4RM.build_security_policy_for('authenticated').owner_can_insert('id');
		policies["User can update own profile"] = W4RM.build_security_policy_for('authenticated').owner_can_update('id');

class ChatMessage:
	var id: StringName
	var lobby_id: StringName
	var profile_id: StringName
	var message: String
	var created_at: int

	static func _w4rm_type_options(opts) -> void:
		opts['lobby_id'] = W4RM.tref("w4online.lobby", {
			external = true,
		})
		opts['profile_id'] = W4RM.tref('Profile', {
			default = 'auth.uid()',
		})

	static func _w4rm_security_policies(policies) -> void:
		policies["Authenticated users can view messages in lobbies they are in"] = \
			W4RM.build_security_policy_for('authenticated').can_select_if('w4online.user_in_lobby(lobby_id)');
		policies["Authenticated users can only post messages in lobbies they are in"] = \
			W4RM.build_security_policy_for('authenticated').can_insert_if('w4online.user_in_lobby(lobby_id)');

	static func _w4rm_triggers(triggers, builder) -> void:
		builder.force_default('id')
		builder.force_default('profile_id')
		builder.cannot_update('lobby_id')
		builder.force_current_time_on_insert('created_at')

static func setup_mapper(mapper) -> void:
	mapper.add_table("Profile", Profile)
	mapper.add_table("ChatMessage", ChatMessage)
	# Publish ChatMessage so we can receive realtime events when one is inserted.
	mapper.publish(ChatMessage)
	mapper.done()

# Script to create the database runnable via the W4 editor plugin.
static func run_static(sdk: W4Client) -> void:
	setup_mapper(sdk.mapper)
	var okay = await sdk.mapper.init_db()
	print("Created DB: %s" % okay)

var lobby
var chat_watcher

# Demonstrates how to use chat.
func _ready() -> void:
	setup_mapper(W4GD.mapper)

	const email = 'testguy@example.com'
	const password = 'testing123'

	# Login or create account.
	var result = await W4GD.auth.login_email(email, password).async()
	if result.is_error():
		result = await W4GD.auth.signup_email(email, password).async()
		if result.is_error():
			print("ERROR: Unable to create account or login")
			return

	# Set username on profile.
	var profile = await W4GD.mapper.get_by_id(Profile, W4GD.get_identity().get_uid())
	if profile == null:
		profile = Profile.new()
		profile.username = "Test Guy"
		await W4GD.mapper.create(profile)

	# Create a new lobby.
	result = await W4GD.matchmaker.create_lobby().async()
	if result.is_error():
		print("ERROR: Unable to create lobby")
		return
	lobby = result.get_data()

	# Subscribe to chat messages in this lobby.
	chat_watcher = W4GD.mapper.create_watcher(
		ChatMessage,
		self._on_chat_message_inserted,
		self._on_chat_message_updated,
		self._on_chat_message_deleted,
		'lobby_id=eq.' + lobby.id)

	# Wait a little while for the watcher to get connected.
	await get_tree().create_timer(1.0).timeout

	# Create a chat message.
	var chat_message = ChatMessage.new()
	chat_message.lobby_id = lobby.id
	chat_message.message = "Hi! I'm here - let's play :-)"
	await W4GD.mapper.create(chat_message)

func _on_chat_message_inserted(chat_message) -> void:
	# Look up the username.
	var profile = await W4GD.mapper.get_by_id(Profile, chat_message.profile_id)
	if profile == null:
		print("ERROR: Unable to look up user name for ", chat_message.profile_id)
		return

	print("[%s @ %s] %s" % [
		profile.username,
		Time.get_date_string_from_unix_time(chat_message.created_at),
		chat_message.message
	])

func _on_chat_message_updated(_x) -> void:
	pass

func _on_chat_message_deleted(_x) -> void:
	pass
