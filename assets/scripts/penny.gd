@tool class_name Penny extends Node

signal on_reload_start
signal on_reload_finish(success: bool)
signal on_reload_cancel
signal on_root_cell_modified

const RECOGNIZED_EXTENSIONS : PackedStringArray = [ "pen", "penny" ]
const STAGE_GROUP_NAME := &"penny_stage"
const DEFAULT_MARKER_NAME := &"default_marker"

const INPUT_DEADZONE_DEFAULT := 0.2

const INPUT_DEBUG_WINDOW := &"penny_debug"
const INPUT_ADVANCE := &"penny_advance"
const INPUT_SKIP := &"penny_skip"
const INPUT_ROLL_BACK := &"penny_roll_back"
const INPUT_ROLL_AHEAD := &"penny_roll_ahead"
const INPUT_SCROLL_UP := &"penny_scroll_up"
const INPUT_SCROLL_DOWN := &"penny_scroll_down"

const SETTING_INPUT_DEBUG_WINDOW := "input/" + INPUT_DEBUG_WINDOW
const SETTING_INPUT_ADVANCE := "input/" + INPUT_ADVANCE
const SETTING_INPUT_SKIP := "input/" + INPUT_SKIP
const SETTING_INPUT_ROLL_BACK := "input/" + INPUT_ROLL_BACK
const SETTING_INPUT_ROLL_AHEAD := "input/" + INPUT_ROLL_AHEAD
const SETTING_INPUT_SCROLL_UP := "input/" + INPUT_SCROLL_UP
const SETTING_INPUT_SCROLL_DOWN := "input/" + INPUT_SCROLL_DOWN

static var SCRIPT_RESOURCE_LOADER := preload("uid://0mqljw2t364x").new()
static var PENNY_DEBUG_SCENE := preload("uid://cfkhtume00g5e")
static var DECOR_REGISTRY_DEFAULT : DecorRegistry = preload("uid://drmpmcuvh657f")


static var inst : Penny
static var is_reloading_bulk : bool = false
static var is_all_scripts_valid : bool = true
static var script_reload_timestamps : Dictionary[String, int]

static var scripts : Array[PennyScript]
static var inits : Array[Stmt]
static var labels : Dictionary[StringName, Stmt]

static var static_host : PennyHost
static var errors : Array[String] :
	get:
		var result : Array[String] = []
		for script in scripts:
			result.append_array(script.errors)
		return result

static var reload_cache_mode : ResourceLoader.CacheMode :
	get: return ResourceLoader.CacheMode.CACHE_MODE_REUSE if OS.has_feature("template") else ResourceLoader.CacheMode.CACHE_MODE_REPLACE


static func _static_init() -> void:
	if not Engine.is_editor_hint():
		DECOR_REGISTRY_DEFAULT.register_all_decors()


static func register_formats() -> void:
	ResourceLoader.add_resource_format_loader(SCRIPT_RESOURCE_LOADER)


static func find_script_from_path(path: String) -> PennyScript:
	for i in scripts: if i.resource_path == path: return i
	return null


static func get_stmt_from_address(path: String, index: int) -> Stmt:
	for script in scripts:
		if script.resource_path != path: continue
		return script.stmts[index]
	return null


static func get_stmt_from_label(label_name: StringName) -> Stmt:
	if labels.has(label_name):
		return labels[label_name]
	else:
		printerr("Label '%s' does not exist in any loaded script." % label_name)
		return null


static func load_script(path: String, type_hint := "") -> Variant:
	return ResourceLoader.load(path, type_hint, reload_cache_mode)


static func reload_all() -> void:
	is_reloading_bulk = true
	var result : Array[PennyScript] = []

	script_reload_timestamps.clear()
	for path in Penny.retrieve_all_paths():
		script_reload_timestamps[path] = FileAccess.get_modified_time(path)
		result.push_back(Penny.load_script(path))

	Penny.reload_many(result)
	is_reloading_bulk = false


static func reload_updated() -> void:
	is_reloading_bulk = true
	var result : Array[PennyScript] = []

	var new_paths := Penny.retrieve_all_paths()
	var del_paths : Array[String] = []
	for k in script_reload_timestamps.keys():
		del_paths.push_back(k)
	for path in new_paths:
		if script_reload_timestamps.has(path):
			del_paths.erase(path)
			if FileAccess.get_modified_time(path) != script_reload_timestamps[path]:
				result.push_back(Penny.load_script(path))
		else:
			result.push_back(Penny.load_script(path))
		script_reload_timestamps[path] = FileAccess.get_modified_time(path)
	for path in del_paths:
		script_reload_timestamps.erase(path)

	Penny.reload_many(result)
	is_reloading_bulk = false


static func reload_single(script : PennyScript) -> void:
	## Check this so that scripts loading independently will reload the environment, but scripts loading in bulk will not.
	if is_reloading_bulk: return
	Penny.reload_many([script])


static func reload_many(many: Array[PennyScript] = scripts):
	inst.on_reload_start.emit()

	if many.size() > 0:

		for script in many:
			var i : int = -1
			for j in scripts.size():
				if scripts[j].id == script.id: i = j; break
			if i == -1: scripts.push_back(script)
			else: scripts[i] = script

		labels.clear()

		for script in scripts:
			for stmt in script.stmts:
				if stmt == null: continue
				stmt.reload()

		is_all_scripts_valid = errors.is_empty()

		if is_all_scripts_valid:
			print("Successfully loaded %s script(s), %s total." % [str(many.size()), str(scripts.size())])
		else:
			printerr("Failed to load one or more scripts:")
			for e in errors:
				printerr("\t" + e)

		inst.on_reload_finish.emit(is_all_scripts_valid)
	elif is_all_scripts_valid:
		inst.on_reload_cancel.emit()
	else:
		inst.on_reload_finish.emit(false)


func _enter_tree() -> void:
	inst = self
	Penny.register_formats()


func _ready():
	if not Engine.is_editor_hint():
		static_host = PennyHost.new()
		static_host.name = "static_host"
		static_host.allow_rolling = false
		self.add_child.call_deferred(static_host)

		if OS.is_debug_build():
			var debug_canvas := CanvasLayer.new()
			debug_canvas.layer = 256
			self.add_child.call_deferred(debug_canvas)
			var debug : PennyDebug = PENNY_DEBUG_SCENE.instantiate()
			on_reload_start.connect(debug.on_reload_start.emit)
			on_reload_finish.connect(debug.on_reload_finish.emit)
			on_reload_cancel.connect(debug.on_reload_cancel.emit)
			debug_canvas.add_child.call_deferred(debug)

	Penny.reload_all.call_deferred()

	if not Engine.is_editor_hint():
		inits.sort_custom(StmtInit.sort)
		static_host.perform_inits_selective.call_deferred(scripts)


func _notification(what: int) -> void:
	if not OS.has_feature("template"):
		if what == NOTIFICATION_APPLICATION_FOCUS_IN:
			if Engine.is_editor_hint():
				Penny.register_formats()
			else:
				Penny.reload_updated.call_deferred()


static func retrieve_all_paths() -> PackedStringArray :
	var result := PackedStringArray()
	for ext in Penny.RECOGNIZED_EXTENSIONS:
		# result.append_array(PennyUtils.get_paths_in_folder("res://", RegEx.create_from_string(r"^_.*\.pen$")))
		result.append_array(PennyUtils.get_paths_in_folder("res://", RegEx.create_from_string(ext + "$")))
	return result


static func get_value_as_string(value: Variant) -> String:
	if value == null:
		return "NULL"
	elif value is Cell:
		return value.key_name
	elif value is String:
		return "\"%s\"" % value
	elif value is Color:
		return "#" + value.to_html()
	return str(value)


static func get_value_as_bbcode_string(value: Variant) -> String:
	var s := get_value_as_string(value)
	if value is Cell or value is Expr:
		return "[color=peru]%s[/color]" % s
	if value is Color:
		return "[color=%s]%s[/color]" % [s, s]
	return "[color=deep_pink]%s[/color]" % s
