## Utilities for creating table triggers.
extends RefCounted

## A utility class for creating triggers for the given table.
class W4RMTriggerBuilder:
	var table

	var _before_insert := ''
	var _before_update := ''
	var _before_delete := ''

	## Creates a trigger builder for the given table.
	func _init(p_table):
		table = p_table

	## Adds a trigger that will prevent the given column from being updated.
	func cannot_update(p_column: String) -> void:
		var sql = """
			NEW."%s" := OLD."%s";
		""" % [p_column, p_column]
		_before_update += sql

	func _get_force_value_sql(p_column: String, p_value: String) -> String:
		return """
			NEW."%s" := %s;
		""" % [p_column, p_value]

	## Adds a trigger that will force the given column to be the given value on insert.
	func force_value_on_insert(p_column: String, p_value: String) -> void:
		_before_insert += _get_force_value_sql(p_column, p_value)

	## Adds a trigger that will force the given column to be the given value on update.
	func force_value_on_update(p_column: String, p_value: String) -> void:
		_before_update += _get_force_value_sql(p_column, p_value)

	## Adds a trigger that will force the given column to be the given value on insert
	## and prevent it being updated later.
	func force_value(p_column: String, p_value: String) -> void:
		force_value_on_insert(p_column, p_value)
		cannot_update(p_column)

	func _get_default(p_column: String):
		var opt = table.get_table_options().get(p_column)
		if opt == null:
			push_error("Can't get default: %s member doesn't have any options" % p_column)
			return null
		if opt.default == null or opt.default == &"":
			push_error("Can't get default: %s member doesn't have 'default' option" % p_column)
			return null
		return opt.default

	## Adds a trigger that will set the given column to its default if NULL is inserted.
	##
	## Won't do anything if the column has no default, or that default is NULL.
	func optional_default_on_insert(p_column: String) -> void:
		var default = _get_default(p_column)
		if default == null:
			return
		var sql = """
			IF NEW."%s" IS NULL THEN
				NEW."%s" := %s;
			END IF;
			""" % [p_column, p_column, default]
		_before_insert += sql

	## Convenience alias for [method optional_default_on_insert].
	func optional_default(p_column: String) -> void:
		optional_default_on_insert(p_column)

	## Adds a trigger that will force the given column to its default value on insert.
	func force_default_on_insert(p_column: String) -> void:
		var default = _get_default(p_column)
		if default == null:
			return
		force_value_on_insert(p_column, default)

	## Adds a trigger that will force the given column to its default value on insert
	## and prevent it being updated later.
	func force_default(p_column: String) -> void:
		force_default_on_insert(p_column)
		cannot_update(p_column)

	func _get_set_time_sql(p_column: String) -> String:
		var type = table.get_record_members().get(p_column)
		if type == null:
			push_error("Can't set time: no type for %s member" % p_column)
			return ""
		var sql: String
		if type == &"timestamp" or type == &"string":
			sql = """
			NEW."%s" := CURRENT_TIMESTAMP();
			""" % p_column
		else:
			sql = """
			NEW."%s" := FLOOR(EXTRACT(EPOCH FROM NOW()));
			""" % p_column
		return sql

	## Adds a trigger that will force the given column to be set to the current time on insert.
	func force_current_time_on_insert(p_column: String) -> void:
		_before_insert += _get_set_time_sql(p_column)

	## Adds a trigger that will force the given column to be set to the current time on update.
	func force_current_time_on_update(p_column: String) -> void:
		_before_update += _get_set_time_sql(p_column)

	## Adds a trigger that will force the given column to be set to the current time on insert and update.
	func force_current_time(p_column: String) -> void:
		_before_insert += _get_set_time_sql(p_column)
		_before_update += _get_set_time_sql(p_column)

	func _set_trigger(p_triggers: Dictionary, p_name: String, p_value: String):
		if p_value == "":
			return
		if not p_name in p_triggers:
			p_triggers[p_name] = ""
		p_triggers[p_name] += p_value + """
			return NEW;
		"""

	## Puts all the triggers added to this builder into the given Dictionary.
	func build(p_triggers: Dictionary):
		_set_trigger(p_triggers, 'before_insert', _before_insert)
		_set_trigger(p_triggers, 'before_update', _before_update)
