## The result of an HTTP request.
extends RefCounted

## The result status.
enum ResultStatus { DONE = 0, PENDING = 1, CANCELLED = 2, ERROR = 3 }

var result_status = ResultStatus.PENDING
var http_request_result := 0
var http_status_code := 0
var headers := PackedStringArray()
var body := PackedByteArray()
var json_parser := JSON.new()


## Returns true if the request is still pending; otherwise, false.
func is_pending() -> bool:
	return result_status == ResultStatus.PENDING


## Returns a Dictionary of the response headers.
func dict_headers() -> Dictionary:
	var out = {}
	for v in self.headers:
		var split = v.split(':', true, 1)
		if split.size() == 2:
			out[split[0].strip_edges().to_lower()] = split[1].strip_edges()
	return out


## Parses the response body as JSON and returns it.
func json_result() -> Variant:
	var json_string = self.body.get_string_from_utf8()
	var err = json_parser.parse(json_string)
	if err == OK:
		var data_received = json_parser.get_data()
		var type = typeof(data_received)
		if type == TYPE_DICTIONARY or type == TYPE_ARRAY or type == TYPE_NIL:
			return data_received
		else:
			push_error("Unexpected data type: %d" % typeof(data_received))
	else:
		push_error(
			"JSON Parse Error: ",
			json_parser.get_error_message(),
			" in ",
			json_string,
			" at line ",
			json_parser.get_error_line()
		)
	return null


## Returns the response body as a UTF-8 string.
func text_result() -> String:
	return body.get_string_from_utf8()


## Returns the response body as bytes.
func bytes_result() -> PackedByteArray:
	return body


## Returns true if the request resulted in an error; otherwise, false.
func is_error() -> bool:
	return result_status == ResultStatus.ERROR


## Returns true if the response is an HTTP error; otherwise, false.
func is_http_error() -> bool:
	return http_status_code >= 400


## Returns true if the response is an HTTP success; otherwise, false.
func is_http_success() -> bool:
	return http_status_code >= 200 and http_status_code < 300


## Returns true if the response is an HTTP redirect; otherwise, false.
func is_http_redirect() -> bool:
	return http_status_code >= 300 and http_status_code < 400


## Returns the HTTP status code of the response.
func get_http_status_code() -> int:
	return http_status_code


func _to_string() -> String:
	return str([http_request_result, http_status_code, headers, body.slice(0, 256), result_status])
