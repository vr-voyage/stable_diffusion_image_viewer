extends Container

var dictionary_item = load("res://InfoDictionaryItem.tscn")

@export var ui_list:Container

func clear() -> void:
	for child in ui_list.get_children():
		ui_list.remove_child(child)
		child.queue_free()

func show_dictionary(dictionary:Dictionary) -> void:
	if dictionary == null:
		return
	clear()
	for key in dictionary:
		var item = dictionary_item.instantiate()
		ui_list.add_child(item)
		item.set_content(key, str(dictionary[key]))

