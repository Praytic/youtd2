## The Supabase pgmeta end-point at /pg.
##
## This end-point is only enabled during development. It is disabled on production workspaces for security.
extends "endpoint.gd"


## Returns an escaped SQL identifier.
func sql_identifier(p_name: String):
	return '"%s"' % p_name.replace('"', '_')


## Returns an escaped SQL string.
func sql_string(p_string: String):
	return "'%s'" % p_string.replace("'", "\\'")


## Runs the given SQL query.
func query(p_query : String):
	return POST("/query", {
		"query": p_query
	})


## Gets a list of all the tables in the database.
func get_tables(include_system_schemas:=false, limit:=0, offset:=0):
	return GET("/tables", _null_stripped({
		"include_system_schemas": "true" if include_system_schemas else null,
		"limit": limit if limit else null,
		"offset": offset if offset else null,
	}))


## Gets the given table.
func get_table(id: String):
	return GET("/tables/" + id)


## Creates a new table.
func create_table(name: String, schema: String = "public", comment=null):
	return POST("/tables", _null_stripped({
		"name": name,
		"schema": schema,
		"comment": comment,
	}))


## Alters the given table.
func alter_table(id: String, name=null, schema=null, primary_keys=null,
	rls_enabled=null, rls_forced=null, replica_identity_index=null, comment=null
	):
	return PATCH("/tables/" + id, _null_stripped({
		"name": name if name else null,
		"schema": schema if schema else null,
		"primary_keys": primary_keys,
		"rls_enabled": rls_enabled,
		"rls_forced": rls_forced,
		"replica_identity_index": replica_identity_index,
		"comment": comment,
	}))


## Deletes the given table.
func delete_table(id: String, cascade=false):
	return DELETE("/tables/" + id, null, _null_stripped({
		"cascade": "true" if cascade else null
	}))


## Gets the given column.
func get_column(column_id: String):
	return GET("/columns/" + column_id)


## Gets all columns.
func get_columns(include_system_schemas:=false, limit:=0, offset:=0):
	return GET("/columns", _null_stripped({
		"include_system_schemas": "true" if include_system_schemas else null,
		"limit": limit if limit else null,
		"offset": offset if offset else null,
	}))


## Creates a column.
func create_column(table_id: String, name: String, type: String,
	default_value=null, default_value_format=null, is_nullable=null,
	is_primary_key=null, is_unique=null, check=null, is_identity=null,
	identity_generation=false, comment=null):
	return POST("/columns", _null_stripped({
		"table_id": table_id,
		"name": name,
		"type": type,
		"default_value": default_value,
		"is_nullable": is_nullable,
		"is_primary_key": is_primary_key,
		"is_unique": is_unique,
		"check": check,
		"default_value_format": default_value_format,
		"is_identity": is_identity,
		"identity_generation": identity_generation,
		"comment": comment,
	}))

## Updates the given column.
func update_column(column_id: String, name=null, type=null,
	drop_default=null, default_value=null, default_value_format=null,
	is_nullable=null, is_unique=null, is_identity=null,
	identity_generation=false, comment=null):
	return PATCH("/columns/" + column_id, _null_stripped({
		"name": name,
		"drop_default": drop_default,
		"type": type,
		"default_value": default_value,
		"is_nullable": is_nullable,
		"is_unique": is_unique,
		"default_value_format": default_value_format,
		"is_identity": is_identity,
		"identity_generation": identity_generation,
		"comment": comment,
	}))


## Deletes the given column.
func delete_column(column_id: String):
	return DELETE("/columns/" + column_id)
