extends Panel

@export var ui_image:TextureRect
@export var ui_image_info:Control

var image:Image = Image.new()
var zoom_amount:Vector2 = Vector2(0.1,0.1)

func report_error(message:String):
	printerr(message)

func _handle_picture_size():
	if ui_image.texture == null:
		return
	var texture_size:Vector2i = ui_image.texture.get_size()
	var container_size:Vector2i = Vector2i(ui_image.get_parent().size)
	# Make sure the image is stretched correctly if it's too big, by default
	if Vector2i(min(texture_size.x, container_size.x), min(texture_size.y, container_size.y)) != texture_size:
		ui_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		ui_image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ui_image.pivot_offset = container_size / 2

func show_image(image_data:PackedByteArray):
	if not PNGHelper.is_valid_png_header(image_data):
		report_error("Unknown file format")
		return
	if image.load_png_from_buffer(image_data) != OK:
		report_error("Invalid file")
		return

	ui_image.scale = Vector2.ONE

	var texture = ui_image.texture
	var image_size:Vector2i = Vector2i(image.get_size())

	if texture == null:
		ui_image.texture = ImageTexture.create_from_image(image)
	else:
		if image_size == Vector2i(ui_image.texture.get_size()):
			ui_image.texture.update(image)
		else:
			ui_image.texture.set_image(image)
			

	_handle_picture_size()
	ui_image_info.show_data(image_data)

func show_image_file(filepath:String):
	var f:File = File.new()
	var ret:int = f.open(filepath, File.READ)
	if ret != OK:
		printerr("Could not open %s .\nError code : %d" % [filepath, ret])
		return
	show_image(f.get_buffer(f.get_length()))
	f.close()

# Called when the node enters the scene tree for the first time.
func _ready():
	image = Image.new()
	pass # Replace with function body.

var info_panel_opened:bool = false

func toggle_info_panel():
	info_panel_opened = !info_panel_opened
	var tween:Tween = create_tween().set_parallel(true)
	var position_x:int = -400 * int(info_panel_opened)
	tween.tween_property($Control/VBoxContainer, "position:x", position_x, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Control/InfoButton, "position:x", position_x + -38, 0.5).set_trans(Tween.TRANS_SINE)

func _on_info_button_pressed():
	toggle_info_panel()

func _zoom_in():
	if ui_image.scale < Vector2(8,8):
		ui_image.scale += zoom_amount

func _zoom_out():
	print("Zoom out !")
	if ui_image.scale > Vector2(0,0):
		ui_image.scale -= zoom_amount

func _unhandled_input(event):
	var mouse_event = event as InputEventMouseButton
	if mouse_event == null:
		return
	# Only handling CTRL+Mouse here.
	# Also, only handling mouse button press
	if not mouse_event.pressed:
		return
	if not mouse_event.ctrl_pressed:
		return

	var input_handled:bool = false
	match mouse_event.button_index:
		4:
			_zoom_in()
			input_handled = true
		5:
			_zoom_out()
			input_handled = true

	if input_handled:
		get_viewport().set_input_as_handled()



func _on_image_container_resized():
	print("Resized")
	_handle_picture_size()
	pass # Replace with function body.
