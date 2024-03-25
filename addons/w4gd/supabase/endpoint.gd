## A Supabase REST end-point under a specific base path (ex. [code]/auth/v1/[/code] or [code]/storage/v1/[/code]).
extends RefCounted

const Client = preload("../rest-client/client.gd")
const Request = preload("../rest-client/client_request.gd")
const Parser = preload("poly_result.gd")
const Identity = preload("identity.gd")
const PolyResult = Parser.PolyResult

## The REST client.
var client : Client
## The base path.
var endpoint := ""
## The Supabase identity.
var identity : Identity

func _init(p_client: Client, p_endpoint: String, p_identity):
	client = p_client
	endpoint = p_endpoint
	identity = p_identity


func _null_stripped(from : Dictionary):
	var out = {}
	for k in from:
		if typeof(from[k]) == TYPE_NIL:
			continue
		out[k] = from[k]
	return out


## Parses a result from the REST client into a PolyResult.
static func parse_result(result, binary:=false) -> PolyResult:
	return Parser.parse_result(result, binary)


## Parses the result of a HEAD request from the REST client into a PolyResult.
static func _parse_head_result(result) -> PolyResult:
	if result.is_http_success():
		return Parser.PolyResult.new(result.dict_headers())
	return Parser.parse_result(result, true)


## Makes a GET request.
func GET(path, query : Dictionary = {}, extra_headers : Dictionary = {}, binary:=false) -> Request:
	return client.GET(endpoint + path, query, extra_headers).then(parse_result.bind(binary))


## Makes a HEAD request.
func HEAD(path, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return client.HEAD(endpoint + path, query, extra_headers).then(_parse_head_result)


## Makes a raw GET request, that returns binary data.
func GET_RAW(path, query : Dictionary = {}, extra_headers : Dictionary = {}) -> Request:
	return client.GET(endpoint + path, query, extra_headers).then(parse_result.bind(true))


## Makes a POST request.
func POST(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}, binary:=false) -> Request:
	return client.POST(endpoint + path, data, query, extra_headers).then(parse_result.bind(binary))


## Makes a PUT request.
func PUT(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}, binary:=false) -> Request:
	return client.PUT(endpoint + path, data, query, extra_headers).then(parse_result.bind(binary))


## Makes a PATCH request.
func PATCH(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}, binary:=false) -> Request:
	return client.PATCH(endpoint + path, data, query, extra_headers).then(parse_result.bind(binary))


## Makes a DELETE request.
func DELETE(path, data = null, query : Dictionary = {}, extra_headers : Dictionary = {}, binary:=false) -> Request:
	return client.DELETE(endpoint + path, data, query, extra_headers).then(parse_result.bind(binary))
