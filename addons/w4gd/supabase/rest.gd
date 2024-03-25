## The Supabase PostgREST end-point at /rest/v1.
extends "endpoint.gd"

## Calls the given Postgres function.
##
## It may modify the database.
func rpc(p_name : String, p_args=null, p_schema_override : String = ""):
	if p_schema_override == "" and "." in p_name:
		var parts = p_name.split(".", true, 1)
		p_schema_override = parts[0]
		p_name = parts[1]

	var headers := {}
	if p_schema_override != "":
		headers['Content-Profile'] = p_schema_override
	return POST("/rpc/%s" % p_name, p_args, {}, headers)

## Calls the given Postgres function.
##
## It may [b]not[/b] modify the database.
func rpc_const(p_name : String, p_args=null, p_schema_override : String = ""):
	if p_args == null:
		p_args = {}

	if p_schema_override == "" and "." in p_name:
		var parts = p_name.split(".", true, 1)
		p_schema_override = parts[0]
		p_name = parts[1]

	var headers := {}
	if p_schema_override != "":
		headers['Accept-Profile'] = p_schema_override
	return GET("/rpc/%s" % p_name, p_args, headers)
