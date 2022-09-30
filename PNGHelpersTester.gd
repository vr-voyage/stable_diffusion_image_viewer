extends VBoxContainer

func _manage_dropped_file(filepaths:PackedStringArray) -> void:
	var filepath:String = filepaths[0]
	var file:File = File.new()
	print("Starting to read %s" % [filepath])
	if file.open(filepath, File.READ) != OK:
		printerr("Could not open %s" % [filepath])
		return

	print("Parsing file data")
	var dict:Dictionary = PNGHelper.get_metadata(file.get_buffer(file.get_length()))
	file.close()

	if dict.is_empty():
		printerr("No data returned")
		return

	$VBoxContainer.show_dictionary(dict)

func _ready():
	var metadata_string:String = (
		"Degu by Alex Russell Flint\n" +
		"Steps: 64, Sampler: PLMS, CFG scale: 7.5, Seed: 3185236643, Size: 512x512, Model hash: 7460a6fa")
	var automatic_metadata:Dictionary = {
		"parameters": metadata_string
	}
	get_tree().get_root().connect("files_dropped", _manage_dropped_file)
	print(_automatic_sd_to_txt2img(automatic_metadata))

func _string_contains_all(string_data:String, all_substrings:PackedStringArray) -> bool:
	for substring in all_substrings:
		if not string_data.contains(substring):
			return false
	return true

const automatic_sd_keys:Array[String] = [
	"Steps",
	"Sampler",
	"CFG scale",
	"Seed",
	"Size"
]

func _is_automatic_sd_data(metadata:Dictionary) -> bool:
	if not metadata.has("parameters"):
		return false

	var metadata_string:String = metadata["parameters"] as String
	if metadata_string == null:
		return false

	var lines:PackedStringArray = metadata_string.split("\n")
	if len(lines) < 2:
		return false
	return _string_contains_all(lines[-1], automatic_sd_keys)

func _dict_string_to_dict(str:String, key_delimiter:String = ":", space_delimiter:String = ",") -> Dictionary:
	var dict:Dictionary = {}
	if str == null:
		return dict

	for part in str.split(space_delimiter, false):
		var key_value:PackedStringArray = part.split(key_delimiter, false)
		if len(key_value) != 2:
			continue
		dict[key_value[0].strip_edges()] = key_value[1].strip_edges()

	print(dict)
	return dict

func _automatic_sd_to_txt2img(metadata:Dictionary) -> String:
	if not _is_automatic_sd_data(metadata):
		printerr("This should not happen !")
		return ""

	# FIXME Doing the same job twice ! We already splitted the string before.
	var lines:PackedStringArray = metadata["parameters"].split("\n")

	# Get the data as a Dictionary
	var automatic_sd_configuration:Dictionary = _dict_string_to_dict(lines[-1])
	if not automatic_sd_configuration.has_all(automatic_sd_keys):
		printerr("Could not retrieve a valid dictionary for AUTOMATIC data")
		return ""

	# Make sure the prompt is sanitized for shells
	# Which englobing everything inside single-quotes, since
	# single-quoted content isn't interpreted by most shells.
	var prompt:String = "\n".join(lines.slice(0, -1)).replace("'", "\\'")
	var dimensions:PackedStringArray = automatic_sd_configuration["Size"].split("x")
	if len(dimensions) < 2:
		printerr("Invalid dimensions informations")
		return ""

	var width:String = dimensions[0]
	var height:String = dimensions[1]

	var command_line_prefix:String = "./dream.py '%s' -W%s -H%s" % [prompt, width, height]

	

	var command_line:String = command_line_prefix + (
		" --sampler {Sampler}"+
		" --cfg_scale {CFG scale}"+
		" --steps {Steps}"+
		" --seed {Seed}").format(automatic_sd_configuration)
	return command_line
