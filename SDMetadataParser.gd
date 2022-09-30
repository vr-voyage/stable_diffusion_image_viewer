extends Node

var sd_metadata_classes = {
	"Voyage": StableDiffusionDataVoyage,
	"AUTOMATIC": StableDiffusionDataAUTOMATIC 
}

func get_info(from:Dictionary, out:Dictionary) -> bool:

	var command_line:String = ""
	for typename in sd_metadata_classes:
		var sd_type_class = sd_metadata_classes[typename]
		command_line = sd_type_class.build_command_line(from)
		if not command_line.is_empty():
			out["type"] = typename
			out["command_line"] = command_line
			return true

	return false
