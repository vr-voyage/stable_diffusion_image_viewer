extends Button

var current_file_path:String = ""

func _open_file_on_click():
	if current_file_path:
		OS.shell_open(current_file_path.get_base_dir())

func _update_ui():
	if current_file_path:
		text = current_file_path.get_file()
	else:
		text = "StableDiffusion Image Viewer"

func showing_file(filepath:String):
	current_file_path = filepath
	_update_ui()
