extends Node


class IdentityProvider:
	var _api_key: String
	
	func _init(api_key):
		_api_key = api_key
	
	func get_identity():
		pass


class ItchIndentityProvider extends IdentityProvider:
	
	var _http_request: HTTPRequest
	
	func _init(http_request: HTTPRequest):
		_api_key = OS.get_environment("ITCHIO_API_KEY")
		_http_request = http_request
	
	func get_identity():
		var auth_header = [ "Authorization: Bearer %s" % _api_key] 
		var res = _http_request.request("https://itch.io/api/1/key/me", auth_header)
		if res != OK:
			push_error("Could not retrieve identity for itch.io provider.")
