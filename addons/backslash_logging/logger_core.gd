extends Node

var _queue: Array = []
var _pending_sends: Array = []
var _is_sending: bool = false
var _timer: Timer = null
var _http_request: HTTPRequest = null
var _startup_logged: bool = false

var player_id: String = ""
var session_id: String = ""
var version: String = ""

@export var webhook_url: String = "https://script.google.com/macros/s/AKfycbyfdyFGB9FUCBA5DnhfCE5W3Ncir_MaNczcbpAubxcKKeyY04KrrFFIziZErgK392bn/exec"
@export var secret: String = "super_secret_string_123"
@export var max_queue_size: int = 50
@export var flush_interval: float = 10.0

## Initializes the logging node, configures the persistent player ID, generates a dynamic session ID,
## fetches application build version, and sets up helper nodes (HTTPRequest and Timer).
func _ready() -> void:
	_initialize_player_id()
	_initialize_session_id()
	_initialize_version()
	_setup_network_nodes()
	info("Game session started.", "System")

## Loads an existing persistent user ID from the configuration file at user://backslash_logging.cfg
## or generates a new random identifier if one is not found, persisting it back to disk.
func _initialize_player_id() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://backslash_logging.cfg")
	if err == OK:
		player_id = config.get_value("user", "player_id", "")
	
	if player_id == "":
		player_id = _generate_random_hash()
		config.set_value("user", "player_id", player_id)
		config.save("user://backslash_logging.cfg")

## Creates a unique 8-character random alphanumeric hash prefixed with usr_ to represent the local client.
func _generate_random_hash() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var hash_str = "usr_"
	for i in range(8):
		var index = randi() % chars.length()
		hash_str += chars[index]
	return hash_str

## Generates a random session identifier for the current runtime sequence to provide session isolation.
func _initialize_session_id() -> void:
	session_id = str(randi())

## Reads the active application configuration version from the ProjectSettings, falling back to 1.0.0 if undefined.
func _initialize_version() -> void:
	var version_setting = ProjectSettings.get_setting("application/config/version")
	if version_setting != null:
		version = str(version_setting)
	else:
		version = "1.0.0"

## Instantiates and registers the HTTPRequest node and Timer node as children to manage non-blocking async network tasks.
func _setup_network_nodes() -> void:
	_http_request = HTTPRequest.new()
	_http_request.max_redirects = 0
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	_timer = Timer.new()
	_timer.wait_time = flush_interval
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

## Dispatches an informational log message under the specified category.
func info(message: String, category: String = "General", local_only: bool = false) -> void:
	log_event("INFO", category, message, local_only)

## Dispatches a warning log message under the specified category.
func warn(message: String, category: String = "General", local_only: bool = false) -> void:
	log_event("WARN", category, message, local_only)

## Dispatches an error log message under the specified category.
func error(message: String, category: String = "General", local_only: bool = false) -> void:
	log_event("ERROR", category, message, local_only)

## Dispatches a debug log message under the specified category.
func debug(message: String, category: String = "General", local_only: bool = false) -> void:
	log_event("DEBUG", category, message, local_only)

## Enforces the Logging Duality Clause. All events are immediately and synchronously output
## to the local console (using print/printerr) to ensure no reduction in visibility, then pushed
## to the editor's warning/error debugger streams if appropriate, and finally queued for
## asynchronous remote transmission (unless local_only is true to prevent infinite recursive loops).
func log_event(level: String, category: String, message: String, local_only: bool = false) -> void:
	if level != "WARN" and level != "ERROR" and category != "Test":
		if _startup_logged:
			return
		_startup_logged = true

	var timestamp_local = Time.get_datetime_string_from_system(false, false)
	var formatted_msg = "[%s] [%s] [%s] %s" % [timestamp_local, level, category, message]
	
	# --- LOCAL LOGGING SYSTEM (Immediate & Unfiltered) ---
	# Guarantee absolute local visibility via standard print and print_error streams.
	match level:
		"WARN":
			print(formatted_msg)
			push_warning(formatted_msg)
		"ERROR":
			printerr(formatted_msg)
			push_error(formatted_msg)
		_:
			print(formatted_msg)
			
	# If local-only logging is explicitly requested (e.g. internal network/delivery failures),
	# we halt execution here to prevent recursive/infinite loop forwarding.
	if local_only:
		return
			
	# --- REMOTE TELEMETRY FORWARDING SYSTEM ---
	var payload = {
		"secret": secret,
		"timestamp": Time.get_datetime_string_from_system(true, false),
		"level": level,
		"category": category,
		"message": message,
		"session_id": player_id + "_" + session_id,
		"version": version
	}
	
	_queue.append(payload)
	if _queue.size() >= max_queue_size:
		_flush_queue()

## Relocates accumulated logs from the memory queue to the transmission list and initiates sequential network broadcasting.
func _flush_queue() -> void:
	if _queue.is_empty():
		return
		
	_pending_sends.append_array(_queue)
	_queue.clear()
	
	if not _is_sending:
		_send_next()

## Transmits the next pending payload in the queue via a POST request to the Google Apps Script endpoint.
func _send_next() -> void:
	if _pending_sends.is_empty():
		_is_sending = false
		return
		
	_is_sending = true
	var payload = _pending_sends[0]
	var json_string = JSON.stringify(payload)
	var headers = ["Content-Type: text/plain"]
	
	var err = _http_request.request(webhook_url, headers, HTTPClient.METHOD_POST, json_string)
	if err != OK:
		# Log initialization errors locally (local_only) to avoid recursion.
		var err_msg = "HTTP request execution failed to initialize. Error code: %d | Attempted Payload: %s" % [err, json_string]
		log_event("ERROR", "System", err_msg, true)
		_pending_sends.remove_at(0)
		_send_next()

## Resolves the HTTP callback, logs network transfer problems to console if they occur, and triggers transmission of the next queued log.
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if _pending_sends.is_empty():
		return
		
	var failed_payload = _pending_sends[0]
	_pending_sends.remove_at(0)
	
	var is_success = (result == HTTPRequest.RESULT_SUCCESS and response_code == 200) or \
					 (result == HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED and response_code == 302)
	
	if not is_success:
		var reason = body.get_string_from_utf8().strip_edges()
		if reason.is_empty():
			reason = "Connection issue or empty response (Result enum: %d)" % result
		var payload_str = JSON.stringify(failed_payload)
		var err_msg = "Remote delivery failure. Code: %d | Reason: %s | Attempted Payload: %s" % [response_code, reason, payload_str]
		
		# Log remote delivery failure locally (local_only = true) to prevent recursive remote sending loop.
		log_event("ERROR", "System", err_msg, true)
		
	_send_next()

## Triggered automatically at constant intervals to flush pending logs to the backend.
func _on_timer_timeout() -> void:
	_flush_queue()
