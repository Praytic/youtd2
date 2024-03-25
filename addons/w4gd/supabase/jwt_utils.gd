## Internal collection of JWT utility functions.
extends RefCounted


static func _b64_restore(p_b64url : String) -> String:
	var out = p_b64url.replace("-", "+").replace("_", "/")
	while out.length() % 4:
		out += "="
	return out


static func _parse_token_part(p_part : String, p_required : Array) -> Dictionary:
	var json_parser = JSON.new()
	if json_parser.parse(p_part):
		push_error("Failed to parse token: ", p_part)
		return {}
	var part = json_parser.get_data()
	if typeof(part) != TYPE_DICTIONARY:
		push_error("Failed to parse token: ", p_part)
		return {}
	for k in p_required:
		if k in part:
			continue
		push_error("Failed to parse token. Missing required key: ", k, " Part: ", p_part)
		return {}
	return part


static func _validate_token(p_token : String) -> Dictionary:
	var parts = p_token.split(".")
	if parts.size() != 3:
		push_error("Failed to parse token: ", p_token)
		return {}
	var header_json = Marshalls.base64_to_utf8(_b64_restore(parts[0]))
	var payload_json = Marshalls.base64_to_utf8(_b64_restore(parts[1]))
	var header = _parse_token_part(header_json, ["alg", "typ"])
	if header.is_empty():
		return {}
	var payload = _parse_token_part(payload_json, ["exp", "role"])
	if payload.is_empty():
		return {}
	return {
		"header": header,
		"payload": payload,
	}


## Returns true if the given JWT token is valid; otherwise, false.
static func validate_token(p_token : String) -> bool:
	return _validate_token(p_token).size() > 0


## Parses the given JWT token.
static func parse_token(p_token : String) -> Dictionary:
	return _validate_token(p_token)
