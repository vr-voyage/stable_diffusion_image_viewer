extends Control

@export var ui_error_unknown_format:Label
@export var ui_error_no_sd_data:Label
@export var ui_error_cant_retrieve_metadata:Label
@export var ui_info_dictionary_data:Control

@export var ui_command_line_button:Button
@export var ui_sd_metadata_parser:Control

var image_metadata:Dictionary = {}

func report_error(message:String) -> void:
	printerr(message)

func reset_ui():
	ui_error_unknown_format.visible = false
	ui_error_no_sd_data.visible = false
	ui_error_cant_retrieve_metadata.visible = false
	ui_command_line_button.visible = false
	ui_command_line_button.disabled = true
	ui_info_dictionary_data.clear()

func show_error(error_code:int):
	match error_code:
		ERR_FILE_UNRECOGNIZED:
			ui_error_unknown_format.visible = true
		ERR_UNAVAILABLE:
			ui_error_no_sd_data.visible = true
		ERR_INVALID_PARAMETER:
			ui_error_cant_retrieve_metadata.visible = true

var sd_metadata_info:Dictionary = {}
const sd_metadata_keys:Array = ["command_line", "type"]

func show_data(data:PackedByteArray):
	reset_ui()
	image_metadata.clear()
	sd_metadata_info.clear()

	if not PNGHelper.is_valid_png_header(data):
		show_error(ERR_FILE_UNRECOGNIZED)
		return

	if PNGHelper.get_metadata_to(data, image_metadata) != OK:
		show_error(ERR_INVALID_PARAMETER)
		return

	if image_metadata.is_empty():
		show_error(ERR_UNAVAILABLE)
		return

	ui_info_dictionary_data.show_dictionary(image_metadata)
	ui_sd_metadata_parser.get_info(image_metadata, sd_metadata_info)
	var has_sd_metadata:bool = sd_metadata_info.has_all(sd_metadata_keys)
	ui_command_line_button.disabled = !has_sd_metadata
	ui_command_line_button.visible = has_sd_metadata
	if has_sd_metadata:
		ui_command_line_button.text = ("Copy command line (%s)" % sd_metadata_info["type"])

func _txt_to_img_button_pressed():
	if not sd_metadata_info.has("command_line"):
		ui_command_line_button.disabled = true
		ui_command_line_button.visible = false
		report_error("You should not be able to click this button")
		return

	DisplayServer.clipboard_set(sd_metadata_info["command_line"])
	var tweener = create_tween()
	tweener.tween_property(ui_command_line_button, "modulate", Color(0.89, 0.81, 0, 1), 0.25)
	tweener.tween_property(ui_command_line_button, "modulate", Color.WHITE, 0.25)

func _on_txt_2_img_button_mouse_exited():
	ui_command_line_button.release_focus()
	pass # Replace with function body.
