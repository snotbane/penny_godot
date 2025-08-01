
## Handles debug tools for the editor only.
@tool
class_name PennyPlugin extends EditorPlugin

const IMPORTER := "res://addons/penny_godot/assets/scripts/penny.gd"
const AUTOLOAD_NAME = "penny"


func _enable_plugin():
	self.add_autoload_singleton(AUTOLOAD_NAME, IMPORTER)
	# EditorInterface.get_resource_filesystem().resources_reimported.connect(_resources_reimported)

	configure_input()

	ProjectSettings.save()


func _disable_plugin():
	self.remove_autoload_singleton(AUTOLOAD_NAME)
	# EditorInterface.get_resource_filesystem().resources_reimported.disconnect(_resources_reimported)


func _resources_reimported(resources: PackedStringArray) -> void:
	for path in resources: for ext in Penny.RECOGNIZED_EXTENSIONS:
		if path.ends_with(ext): _penny_resource_reimported(path); break


func _penny_resource_reimported(path: String) -> void:
	ResourceLoader.load(path)


func configure_input() -> void:
	if ProjectSettings.get_setting(Penny.SETTING_INPUT_DEBUG_WINDOW) == null:
		var penny_debug_input := InputEventKey.new()
		penny_debug_input.physical_keycode = KEY_D
		penny_debug_input.shift_pressed = true

		ProjectSettings.set_setting(Penny.SETTING_INPUT_DEBUG_WINDOW, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_debug_input
			],
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_ADVANCE) == null:
		var penny_advance_input_0 := InputEventKey.new()
		penny_advance_input_0.physical_keycode = KEY_SPACE

		var penny_advance_input_1 := InputEventKey.new()
		penny_advance_input_1.physical_keycode = KEY_X

		var penny_advance_input_2 := InputEventJoypadButton.new()
		penny_advance_input_2.button_index = JOY_BUTTON_A

		ProjectSettings.set_setting(Penny.SETTING_INPUT_ADVANCE, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_advance_input_0,
				penny_advance_input_1,
				penny_advance_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_SKIP) == null:
		# var penny_skip_input_0 := InputEventMouseButton.new()
		# penny_skip_input_0.button_index = MOUSE_BUTTON_RIGHT

		var penny_skip_input_1 := InputEventKey.new()
		penny_skip_input_1.physical_keycode = KEY_ENTER

		var penny_skip_input_2 := InputEventJoypadButton.new()
		penny_skip_input_2.button_index = JOY_BUTTON_B

		ProjectSettings.set_setting(Penny.SETTING_INPUT_SKIP, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				# penny_skip_input_0,
				penny_skip_input_1,
				penny_skip_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_ROLL_BACK) == null:
		var penny_roll_back_input_0 := InputEventMouseButton.new()
		penny_roll_back_input_0.button_index = MOUSE_BUTTON_XBUTTON1

		var penny_roll_back_input_1 := InputEventKey.new()
		penny_roll_back_input_1.physical_keycode = KEY_W

		var penny_roll_back_input_2 := InputEventJoypadButton.new()
		penny_roll_back_input_2.button_index = JOY_BUTTON_DPAD_UP

		ProjectSettings.set_setting(Penny.SETTING_INPUT_ROLL_BACK, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_roll_back_input_0,
				penny_roll_back_input_1,
				penny_roll_back_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_ROLL_AHEAD) == null:
		var penny_roll_ahead_input_0 := InputEventMouseButton.new()
		penny_roll_ahead_input_0.button_index = MOUSE_BUTTON_XBUTTON2

		var penny_roll_ahead_input_1 := InputEventKey.new()
		penny_roll_ahead_input_1.physical_keycode = KEY_S

		var penny_roll_ahead_input_2 := InputEventJoypadButton.new()
		penny_roll_ahead_input_2.button_index = JOY_BUTTON_DPAD_DOWN

		ProjectSettings.set_setting(Penny.SETTING_INPUT_ROLL_AHEAD, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_roll_ahead_input_0,
				penny_roll_ahead_input_1,
				penny_roll_ahead_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_SCROLL_UP) == null:
		var penny_scroll_up_input_0 := InputEventMouseButton.new()
		penny_scroll_up_input_0.button_index = MOUSE_BUTTON_WHEEL_UP

		var penny_scroll_up_input_1 := InputEventKey.new()
		penny_scroll_up_input_1.physical_keycode = KEY_UP

		var penny_scroll_up_input_2 := InputEventJoypadMotion.new()
		penny_scroll_up_input_2.axis = JOY_AXIS_RIGHT_Y
		penny_scroll_up_input_2.axis_value = -1.0

		ProjectSettings.set_setting(Penny.SETTING_INPUT_SCROLL_UP, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_scroll_up_input_0,
				penny_scroll_up_input_1,
				penny_scroll_up_input_2,
			]
		})

	if ProjectSettings.get_setting(Penny.SETTING_INPUT_SCROLL_DOWN) == null:
		var penny_scroll_down_input_0 := InputEventMouseButton.new()
		penny_scroll_down_input_0.button_index = MOUSE_BUTTON_WHEEL_DOWN

		var penny_scroll_down_input_1 := InputEventKey.new()
		penny_scroll_down_input_1.physical_keycode = KEY_DOWN

		var penny_scroll_down_input_2 := InputEventJoypadMotion.new()
		penny_scroll_down_input_2.axis = JOY_AXIS_RIGHT_Y
		penny_scroll_down_input_2.axis_value = +1.0

		ProjectSettings.set_setting(Penny.SETTING_INPUT_SCROLL_DOWN, {
			"deadzone": Penny.INPUT_DEADZONE_DEFAULT,
			"events": [
				penny_scroll_down_input_0,
				penny_scroll_down_input_1,
				penny_scroll_down_input_2,
			]
		})
