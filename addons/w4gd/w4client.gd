extends Node
class_name W4Client

const W4RMMapper = preload("w4rm/w4rm_mapper.gd")

const SupabaseClient = preload("supabase/client.gd")
const Auth = preload("supabase/auth.gd")
const PGMeta = preload("supabase/pg_meta.gd")
const Rest = preload("supabase/rest.gd")
const Storage = preload("supabase/storage.gd")
const Realtime = preload("supabase/realtime.gd")
const Identity = preload("res://addons/w4gd/supabase/identity.gd")

## Common type of all SDK requests.
## [codeblock]
## var request : W4Client.APIRequest = W4GD.login_email("user@example.com", "password")
## [/codeblock]
const APIRequest = SupabaseClient.Client.Request
## Common result type for most of the SDK requests.
## [codeblock]
## var request : W4Client.APIRequest = W4GD.login_email("user@example.com", "password")
## var result : W4Client.APIResult = await request.async()
## [/codeblock]
const APIResult = SupabaseClient.Parser.PolyResult
## Common error type for most results.
## [codeblock]
## var request : W4Client.APIRequest = W4GD.login_email("user@example.com", "password")
## var result : W4Client.APIResult = await request.async()
## if result.is_error():
##     var error := result.as_error() # W4Client.APIError
## [/codeblock]
const APIError = SupabaseClient.Parser.ResultError

const Matchmaker = preload("matchmaker/matchmaker.gd")
const Analytics = preload("analytics/analytics.gd")
const SMAuth = preload("smauth/smauth.gd")

const W4ProjectSettings = preload("plugin/w4_project_settings.gd")

var log_function: Callable

var client: SupabaseClient
var mapper: W4RMMapper
var analytics: Analytics
var matchmaker: Matchmaker

# Quick aliases.
var auth: SMAuth
var rest: Rest:
	get: return client.rest if client != null else null
var pg: PGMeta:
	get: return client.pg if client != null else null
var storage: Storage:
	get: return client.storage if client != null else null
var realtime: Realtime:
	get: return client.realtime if client != null else null

func get_identity():
	return client.get_identity() if client != null else null

func _init(config: Dictionary = {}, service:=false):
	process_mode = Node.PROCESS_MODE_ALWAYS
	W4ProjectSettings.add_project_settings()
	if config.is_empty():
		config = W4ProjectSettings.get_config()

	mapper = W4RM.mapper(self, config, service)
	client = mapper.client

	auth = SMAuth.new(client.get_rest_client(), client.get_identity())

	analytics = Analytics.new(client)
	add_child(analytics)

	matchmaker = Matchmaker.new(client)
	add_child(matchmaker)

func _ready() -> void:
	connect_to_realtime()

func connect_to_realtime() -> void:
	if client:
		client.realtime.connection_error.connect(self._on_realtime_connection_error)
		client.realtime.connect_socket()

func _on_realtime_connection_error():
	print ("Realtime disconnected.")
	await get_tree().create_timer(0.1).timeout
	print ("Reconnecting to realtime...")
	client.realtime.connect_socket()

## Returns the default port for game servers.
##
## Can be configured in the project settings ([code]w4games/game_server/default_port[/code]), and
## overridden via the W4CLOUD_GAMESERVER_PORT environment variable.
##
## Usage:
## [codeblock]
## var peer := ENetMultiplayerPeer.new()
## peer.create_server(W4Client.get_server_default_port())
## [/codeblock]
static func get_server_default_port() -> int:
	var env := OS.get_environment("W4CLOUD_GAMESERVER_PORT")
	if env.is_valid_int():
		return env.to_int()
	return W4ProjectSettings.get_server_default_port()


# Log and debug functions
func debug(msg):
	if log_function.is_valid(): log_function.call(0, msg)


func warning(msg):
	if log_function.is_valid(): log_function.call(1, msg)


func error(msg):
	if log_function.is_valid(): log_function.call(2, msg)


func fail():
	breakpoint
	pass
