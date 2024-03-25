## The result of a blocking HTTP request.
extends "client_result.gd"

var http_client := HTTPClient.new()
var poll_delay_usec := 1000

func connect_to_url(url: String, tls_options : TLSOptions = null):
	if not url.begins_with("http://") and not url.begins_with("https://"):
		url = "http://" + url
	var tls = url.begins_with("https://")
	var port := 443 if tls else 80
	var proto_idx := url.find("://") + 3
	var path_idx := url.find("/", proto_idx)
	if path_idx < 0:
		path_idx = url.length()
		url += "/"
	var host := url.substr(proto_idx, path_idx - proto_idx)
	var port_idx = host.rfind(":")
	if port_idx > 0:
		var port_str = host.substr(port_idx + 1)
		if port_str.is_valid_int():
			port = port_str.to_int()
			host = host.substr(0, port_idx)
	var err = http_client.connect_to_host(host, port, tls_options if tls else null)
	if err != OK:
		http_request_result = HTTPRequest.RESULT_CANT_CONNECT
	return err


func wait_connection():
	http_client.poll()
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		OS.delay_usec(poll_delay_usec)
		http_client.poll()


func wait_request():
	http_client.poll()
	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		OS.delay_usec(poll_delay_usec)
		http_client.poll()


func read_body() -> PackedByteArray:
	var rb = PackedByteArray() # Array that will hold the data.
	while http_client.get_status() == HTTPClient.STATUS_BODY:
		# While there is body left to be read
		http_client.poll()
		# Get a chunk.
		var chunk = http_client.read_response_body_chunk()
		if chunk.size() == 0:
			OS.delay_usec(poll_delay_usec)
		else:
			rb = rb + chunk # Append to read buffer.
	return rb


func make_request(path : String, headers : PackedStringArray, method : int, raw_data := PackedByteArray()) -> void:
	result_status = ResultStatus.ERROR

	# Wait until resolved and connected.
	wait_connection()

	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		http_request_result = http_client.get_status()
		return

	var err = http_client.request(method, path, headers)
	if err != OK:
		http_request_result = http_client.get_status()
		return

	# Keep polling for as long as the request is being processed.
	wait_request()

	if not http_client.has_response():
		http_request_result = http_client.get_status()
		return

	result_status = ResultStatus.DONE
	http_request_result = HTTPRequest.RESULT_SUCCESS
	http_status_code = http_client.get_response_code()
	headers = http_client.get_response_headers()
	body = read_body()
	http_client.close()
