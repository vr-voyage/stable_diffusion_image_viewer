extends Panel

@export var ui_image_viewer:Control

@export var ui_button_next_image:TextureButton
@export var ui_button_previous_image:TextureButton

@export var ui_button_current_file:Button

var directory_files:PackedStringArray = PackedStringArray()

func report_error(message:String):
	printerr(message)

func _list_files_by_extension(dirpath:String, extension:String, out_list:PackedStringArray) -> int:
	# TODO
	# DirAccess now supports for get_files_at
	# I might use that in the future, since even with a very big folder, we're
	# speaking about a few megabytes of data in memory, at most.
	var ret:int = OK
	var directory_browser:DirAccess = DirAccess.open(dirpath)
	if not directory_browser:
		ret = DirAccess.get_open_error()
		report_error("Could not open directory %s. Code : %d" % [dirpath, ret])
		return ret


	ret = directory_browser.list_dir_begin()
	if ret != OK:
		report_error("Could not list files in %s" % dirpath)
		return ret

	var directory_separator:String = "\\" if OS.get_name() == "Windows" else "/"
	var next_file:String = "a"

	while next_file != "":
		next_file = directory_browser.get_next()
		if next_file == "":
			break
		if directory_browser.current_is_dir():
			continue
		if not next_file.ends_with(extension):
			continue

		out_list.append(dirpath + directory_separator + next_file)

	directory_browser.list_dir_end()
	return OK

var current_index:int = -1
var navigating:bool = false

func _start_navigation(from_file:String):
	# FIXME : These data should be stored in a theme, IHMO
	current_index = directory_files.find(from_file)
	if current_index == -1:
		report_error("Could not find %s !" % from_file)
	ui_button_next_image.modulate = Color.WHITE
	ui_button_next_image.disabled = false
	ui_button_previous_image.modulate = Color.WHITE
	ui_button_previous_image.disabled = false
	navigating = true

func _stop_navigation():
	navigating = false
	ui_button_next_image.modulate = Color(25,25,25)
	ui_button_next_image.disabled = true
	ui_button_previous_image.modulate = Color(25,25,25)
	ui_button_previous_image.disabled = true

func _start_navigation_from(filepath:String):
	directory_files.clear()
	_list_files_by_extension(filepath.get_base_dir(), ".png", directory_files)
	if not directory_files.is_empty():
		_start_navigation(filepath)
	else:
		_stop_navigation()

func show_file(image_file_path:String):
	_show_image_file(image_file_path)
	_start_navigation_from(image_file_path)

func _handle_files_drop(filepaths:PackedStringArray):
	var image_file_path:String = filepaths[0]
	if not image_file_path.ends_with(".png"):
		report_error("Dropped file is not supported")
		return
	show_file(image_file_path)

func _handle_command_line():
	var command_line_args:PackedStringArray = OS.get_cmdline_args()
	if command_line_args.is_empty():
		return
	var potential_filepath:String = command_line_args[0]
	if not potential_filepath.ends_with(".png"):
		return
	show_file(potential_filepath)

# Called when the node enters the scene tree for the first time.
func _ready():
	print(OS.get_name())
	get_tree().get_root().connect("files_dropped", _handle_files_drop)
	_handle_command_line()


func _current_file() -> String:
	return directory_files[current_index]

func _show_image_file(filepath:String):
	ui_image_viewer.show_image_file(filepath)
	ui_button_current_file.showing_file(filepath)

func _show_current_file():
	_show_image_file(_current_file())

func _show_previous_file():
	current_index -= 1
	if current_index < 0:
		current_index = len(directory_files) - 1
	_show_current_file()

func _show_next_file():
	current_index += 1
	if current_index >= len(directory_files) or current_index < 0:
		current_index = 0
	_show_current_file()

func _on_previous_image_pressed():
	_show_previous_file()

func _on_next_image_pressed():
	_show_next_file()

func _unhandled_input(event):
	if not navigating:
		return

	var mouse_event:InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return

	if not mouse_event.pressed:
		return

	var handled:bool = false
	match mouse_event.button_index:
		4:
			_show_next_file()
			handled = true
		5:
			_show_previous_file()
			handled = true

	if handled:
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event:InputEvent):
	var key_event:InputEventKey = event as InputEventKey
	if key_event == null:
		return

	# We handle on release
	if key_event.pressed:
		return

	var handled:bool = false
	match key_event.keycode:
		KEY_SPACE, KEY_ENTER, KEY_RIGHT, KEY_N, KEY_KP_6:
			if navigating:
				_show_next_file()
				handled = true
		KEY_BACKSPACE, KEY_LEFT, KEY_KP_4, KEY_P:
			if navigating:
				_show_previous_file()
				handled = true
		KEY_I:
			ui_image_viewer.toggle_info_panel()
			handled = true

	if handled:
		get_viewport().set_input_as_handled()
