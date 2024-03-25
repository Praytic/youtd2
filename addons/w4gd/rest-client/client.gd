## A generic REST client.
extends RefCounted

const Request = preload("client_request.gd")
const Result = preload("client_result.gd")

## A node in the scene tree that we can add [HTTPRequest]s to.
var node : Node
## The base URL.
var base_url : String
## The default [TLSOptions].
var default_tls_options : TLSOptions = null
## The default request headers.
var default_headers : PackedStringArray
## A callback for formatting request data.
var data_formatter := _default_data_formatter


## Creates a REST client.
##
## The [param node] parameter is a [Node] in the scene tree that we can add [HTTPRequest]s to.
## The [param url] parameter is the base URL of the service we'll be making requests to.
## The [param headers] parameter is default HTTP headers to pass on each request.
func _init(node : Node, url : String, headers : Dictionary = {}, tls_options : TLSOptions = null):
	self.node = node
	self.base_url = url
	self.default_tls_options = tls_options
	default_headers = headers_from_dict(headers)


func _default_data_formatter(data, headers : PackedStringArray) -> PackedByteArray:
	var type = typeof(data)
	if type == TYPE_NIL:
		return PackedByteArray()
	elif type == TYPE_DICTIONARY or type == TYPE_ARRAY:
		var json = JSON.stringify(data)
		headers.append("content-type:application/json")
		return json.to_utf8_buffer()
	elif type == TYPE_STRING:
		return data.to_utf8_buffer()
	elif type == TYPE_PACKED_BYTE_ARRAY:
		return data
	push_error("Error, failed to encode: ", data, " unsupported type")
	return PackedByteArray()


## Makes a [PackedStringArray] combining the default HTTP headers with the given headers.
func headers_from_dict(headers : Dictionary):
	var out = PackedStringArray(default_headers)
	for k in headers:
		out.append(k + ":" + headers[k])
	return out


## Sets a default HTTP header.
func set_header(header : String, value=null):
	var found = -1
	var h = header.to_lower()
	for i in range(0, default_headers.size()):
		if not default_headers[i].to_lower().begins_with(h + ":"):
			continue
		found = i
		break
	if found >= 0:
		if value == null:
			default_headers.remove_at(found)
		else:
			default_headers[found] = "%s:%s" % [header, value]
	elif value != null:
		default_headers.append("%s:%s" % [header, value])


## Returns an HTTP query string from the given Dictionary.
func query_from_dict(query : Dictionary) -> String:
	if query.is_empty():
		return ""
	var q := ""
	for k in query:
		q += str(k).uri_encode() + "=" + str(query[k]).uri_encode() + "&"
	if q.ends_with("&"):
		return q.substr(0, q.length()-1)
	return q


## Parses an HTTP query string into a Dictionary.
func dict_from_query(query: String) -> Dictionary:
	var query_array = query.split("&")
	var query_dictionary := {}
	for value in query_array:
		var key_value = value.split("=")
		query_dictionary[key_value[0].uri_decode()] = key_value[1].uri_decode()
	return query_dictionary


func _make_request(endpoint : String, query : Dictionary, custom_headers : Dictionary, method : int, data = null) -> Request:
	var req := Request.new()
	var headers = headers_from_dict(custom_headers)
	var body : PackedByteArray = data_formatter.call(data, headers) # May add content type to headers.
	var query_str := query_from_dict(query)
	req.node = node
	req.tls_options = default_tls_options
	req.request_method = method
	req.request_headers = headers
	req.request_body = body
	req.request_url = base_url
	req.request_path = endpoint
	if not query_str.is_empty():
		req.request_path += "?" + query_str
	return req


## Makes a GET request.
func GET(path, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return _make_request(path, query, extra_headers, HTTPClient.METHOD_GET)


## Makes a HEAD request.
func HEAD(path, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return _make_request(path, query, extra_headers, HTTPClient.METHOD_HEAD)


## Makes a POST request.
func POST(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return _make_request(path, query, extra_headers, HTTPClient.METHOD_POST, data)


## Makes a PUT request.
func PUT(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return _make_request(path, query, extra_headers, HTTPClient.METHOD_PUT, data)


## Makes a PATCH request.
func PATCH(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return _make_request(path, query, extra_headers, HTTPClient.METHOD_PATCH, data)


## Makes a DELETE request.
func DELETE(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return _make_request(path, query, extra_headers, HTTPClient.METHOD_DELETE, data)
