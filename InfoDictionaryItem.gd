extends Control

func set_content(key_name:String, key_data:String):
	$VBoxContainer/Key.text = key_name
	$VBoxContainer/Data.text = key_data


func _on_copy_button_pressed():
	DisplayServer.clipboard_set($VBoxContainer/Data.text)
	var tweener = create_tween()
	tweener.tween_property($VBoxContainer/Data, "modulate", Color(0.89, 0.81, 0, 1), 0.25)
	tweener.tween_property($VBoxContainer/Data, "modulate", Color.WHITE, 0.25)
	pass # Replace with function body.
