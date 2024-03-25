## Static class that provides access to everything in w4rm, and some helper functions.
extends RefCounted
class_name W4RM

const W4ProjectSettings = preload("../plugin/w4_project_settings.gd")
const W4RMMapper = preload("w4rm_mapper.gd")
const W4RMConnectors = preload("w4rm_connectors.gd")
const W4RMTables = preload("w4rm_table.gd")
const W4RMSecurity = preload("w4rm_security.gd")
const W4RMTriggers = preload("w4rm_triggers.gd")


## Loads the Supabase client.
static func load_client():
	var Sup = preload("../supabase/client.gd")
	if Sup == null:
		push_error("Failed to load supabase client")
		return null
	return Sup


## Creates a mapper.
##
## [param p_node] is a node that can be used to attach [HTTPRequest]s.
## [param p_config] contains connection information (url, key, etc) for Supabase.
## Set [param p_service] to true if using a service key.
static func mapper(p_node, p_config:={}, p_service:=false):
	var mapper = W4RMMapper.new()
	if p_config.is_empty():
		p_config = W4ProjectSettings.get_config()
	var key = p_config["service_key"] if p_service else p_config["key"]
	var tls_options = TLSOptions.client()
	if p_config.get('unsafe_tls', false):
		tls_options = TLSOptions.client_unsafe()
	var client = load_client().new(p_node, p_config["url"], key, tls_options)
	mapper.connector = W4RMConnectors.w4rm_supabase_connector(client)
	return mapper


## Utility function for setting options on a column.
##
## [codeblock]
## class Profile:
##  var id: StringName
##  static func _w4rm_type_options(opts):
##    opts["id"] = W4RM.option({
##      default = "auth.uid()",
##      unique = true,
##    })
## [/codeblock]
static func option(p_opts:={}):
	return W4RMTables.w4rm_option(p_opts)


## Utility function for settings options on column that holds a reference to another table.
##
## [codeblock]
## class Profile:
##  var some_ref: StringName
##  static func _w4rm_type_options(opts):
##    opts["some_ref"] = W4RM.tref("OtherObject", {
##      nullable = true,
##    })
## [/codeblock]
static func tref(p_ref: String, p_opts:={}):
	# If you need to specify an ID different from "id", pass {"id": "column_name"} as p_opts
	var opts = p_opts.duplicate()
	var sp = p_ref.split(".")
	sp.reverse()
	opts["table"] = sp[0]
	if sp.size() > 1:
		opts["schema"] = sp[1]
	return W4RMTables.w4rm_reference(opts)


## Utility function for setting options on a column that holds a back-reference to another table.
##
## [codeblock]
## class OtherObject:
##  var ref: Dictionary
##  static func _w4rm_type_options(opts):
##    opts["ref"] = W4RM.backref("Profile.some_ref", {
##      map = true,
##    })
## [/codeblock]
static func backref(p_ref: String, p_opts:={}):
	var opts = p_opts.duplicate()
	var sp = p_ref.split(".")
	sp.reverse()
	opts["column"] = sp[0]
	opts["table"] = sp[1]
	if sp.size() > 2:
		opts["schema"] = sp[2]
	return W4RMTables.w4rm_backreference(opts)


## Utility function for creating a table's security policy.
##
## [codeblock]
## class Profile:
##     static func _w4rm_security_policies(policies) -> void:
##         policies["Anyone can view profiles"] = W4RM.security_policy({
##             roles = ['anon', 'authenticated'],
##             command = W4RM.W4RMTables.Command.SELECT,
##         })
## [/codeblock]
static func security_policy(p_opts:={}):
	return W4RMTables.w4rm_security_policy(p_opts)


## Utility function for creating a security policy builder to assist in setting up a table's security policy.
##
## [codeblock]
## class Profile:
##     static func _w4rm_security_policies(policies) -> void:
##         policies["Anyone can view profiles"] = W4RM.build_security_policy_for(['anon', 'authenticated']).can_select();
## [/codeblock]
static func build_security_policy_for(p_roles) -> W4RMSecurity.W4RMSecurityPolicyBuilder:
	return W4RMSecurity.W4RMSecurityPolicyBuilder.new(p_roles)


## Utility function for creating a trigger builder to assist in setting up a table trigger.
##
## [codeblock]
## var tb = W4RM.trigger_builder(table)
## tb.force_default("id")
## vars triggers := {}
## tb.build(triggers)
## [/codeblock]
static func trigger_builder(p_table) -> W4RMTriggers.W4RMTriggerBuilder:
	return W4RMTriggers.W4RMTriggerBuilder.new(p_table)


## Converts a type name into the name of an array of that type.
static func array(p_type: String):
	return p_type + "[]"
