## Utilities for creating security policies for database tables.
extends RefCounted

const W4RMTables = preload("w4rm_table.gd")


## A utility class for creating a security policy for a database table.
class W4RMSecurityPolicyBuilder:
	var roles

	## Creates a security policy for the given role or array of roles.
	func _init(p_roles):
		roles = p_roles

	## Creates a security policy that allows selecting rows from the table if the SQL expression evaluates to true.
	func can_select_if(p_sql_expression: String):
		return W4RMTables.w4rm_security_policy({
			roles = roles,
			command = W4RMTables.W4RMCommand.SELECT,
			using = p_sql_expression,
		})

	## Creates a security policy that allows inserting rows into the table if the SQL expression evaluates to true.
	func can_insert_if(p_sql_expression: String):
		return W4RMTables.w4rm_security_policy({
			roles = roles,
			command = W4RMTables.W4RMCommand.INSERT,
			with_check = p_sql_expression,
		})

	## Creates a security policy that allows updating rows in the table if the SQL expression evaluates to true.
	func can_update_if(p_sql_expression: String):
		return W4RMTables.w4rm_security_policy({
			roles = roles,
			command = W4RMTables.W4RMCommand.UPDATE,
			using = p_sql_expression,
			with_check = p_sql_expression,
		})

	## Creates a security policy that allows deleting rows in the table if the SQL expression evaluates to true.
	func can_delete_if(p_sql_expression: String):
		return W4RMTables.w4rm_security_policy({
			roles = roles,
			command = W4RMTables.W4RMCommand.DELETE,
			using = p_sql_expression,
		})


	## Creates a security policy that allows selecting, inserting, updating or deleting rows in the table if the SQL expression evaluates to true.
	func can_do_anything_if(p_sql_expression: String):
		return W4RMTables.w4rm_security_policy({
			roles = roles,
			command = W4RMTables.W4RMCommand.ALL,
			using = p_sql_expression,
			with_check = p_sql_expression,
		})

	## Creates a security policy that allows selecting rows from the table.
	func can_select():
		return can_select_if('true')

	## Creates a security policy that allows inserting rows into the table.
	func can_insert():
		return can_insert_if('true');

	## Creates a security policy that allows updating rows in the table.
	func can_update():
		return can_update_if('true')

	## Creates a security policy that allows deleting rows from the table.
	func can_delete():
		return can_delete_if('true')

	## Creates a security policy that allows selecting, inserting, updating or deleting rows in the table.
	func can_do_anything():
		return can_do_anything_if('true')

	## Creates a security policy that allows selecting rows from the table, if the current user is the owner (as identified by the given field on the table).
	func owner_can_select(p_owner_field: String):
		return can_select_if("%s = auth.uid()" % sql_identifier(p_owner_field))

	## Creates a security policy that allows inserting rows into the table, if the current user is the owner (as identified by the given field on the table).
	func owner_can_insert(p_owner_field: String):
		return can_insert_if("%s = auth.uid()" % sql_identifier(p_owner_field))

	## Creates a security policy that allows updating rows in the table, if the current user is the owner (as identified by the given field on the table).
	func owner_can_update(p_owner_field: String):
		return can_update_if("%s = auth.uid()" % sql_identifier(p_owner_field))

	## Creates a security policy that allows deleting rows from the table, if the current user is the owner (as identified by the given field on the table).
	func owner_can_delete(p_owner_field: String):
		return can_delete_if("%s = auth.uid()" % sql_identifier(p_owner_field))

	## Creates a security policy that allows selecting, inserting, updating or deleting rows in the table, if the current user is the owner (as identified by the given field on the table).
	func owner_can_do_anything(p_owner_field: String):
		return can_do_anything_if("%s = auth.uid()" % sql_identifier(p_owner_field))

	## Creates a security policy that allows selecting rows from the table, if the current user is the owner (as identified by the given field on the table),
	## and the given SQL expression evaluates to true.
	func owner_can_select_if(p_owner_field: String, p_sql_expression: String):
		return can_select_if("(%s = auth.uid()) AND (%s)" % [sql_identifier(p_owner_field), p_sql_expression])

	## Creates a security policy that allows inserting rows into the table, if the current user is the owner (as identified by the given field on the table),
	## and the given SQL expression evaluates to true.
	func owner_can_insert_if(p_owner_field: String, p_sql_expression: String):
		return can_insert_if("(%s = auth.uid()) AND (%s)" % [sql_identifier(p_owner_field), p_sql_expression])

	## Creates a security policy that allows updating rows in the table, if the current user is the owner (as identified by the given field on the table),
	## and the given SQL expression evaluates to true.
	func owner_can_update_if(p_owner_field: String, p_sql_expression: String):
		return can_update_if("(%s = auth.uid()) AND (%s)" % [sql_identifier(p_owner_field), p_sql_expression])

	## Creates a security policy that allows deleting rows from the table, if the current user is the owner (as identified by the given field on the table),
	## and the given SQL expression evaluates to true.
	func owner_can_delete_if(p_owner_field: String, p_sql_expression: String):
		return can_delete_if("(%s = auth.uid()) AND (%s)" % [sql_identifier(p_owner_field), p_sql_expression])

	## Creates a security policy that allows selecting, inserting, updating or deleting rows in the table, if the current user is the owner (as identified by the given field on the table),
	## and the given SQL expression evaluates to true.
	func owner_can_do_anything_if(p_owner_field: String, p_sql_expression: String):
		return can_do_anything_if("(%s = auth.uid()) AND (%s)" % [sql_identifier(p_owner_field), p_sql_expression])

	## Escapes the given string as a SQL identifier.
	static func sql_identifier(p_identifier: String) -> String:
		return '"%s"' % p_identifier
