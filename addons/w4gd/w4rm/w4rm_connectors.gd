extends RefCounted

class W4RMConnector:

	func query(p_query: String):
		push_error("Not implemented")


	func function(p_func, p_args):
		push_error("Not implemented")


	func channel(p_name: String, p_cond:=""):
		push_error("Not implemented")


class W4RMSupabaseConnector extends W4RMConnector:
	var client = null

	func query(p_query: String):
		return await client.pg.query(p_query).async()


	func function(p_func, p_args: Array):
		var data := {}
		for i in range(p_args.size()):
			data["arg%d" % (i+1)] = p_args[i]
		return await client.rest.rpc(p_func, data).async()


	func channel(p_name: String, p_cond:=""):
		if client == null:
			return null
		var ch = "public:%s" % [p_name]
		if p_cond.length() > 0:
			ch += ":%s" % [p_cond]
		return client.realtime.channel(ch)


static func w4rm_supabase_connector(p_client):
	var conn = W4RMSupabaseConnector.new()
	conn.client = p_client
	return conn
