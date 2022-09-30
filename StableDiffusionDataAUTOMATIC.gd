extends Node

class_name StableDiffusionDataAUTOMATIC

const automatic_sd_keys:Array[String] = [
	"Steps",
	"Sampler",
	"CFG scale",
	"Seed",
	"Size"
]

# Ugh ! You'd think they would put the codename
# inside the metadata...
const sampler_name_to_code:Dictionary = {
	"ddim": "ddim",
	"dpm2 a": "k_dpm_2_a",
	"dpm2": "k_dpm_2",
	"euler a": "k_euler_a",
	"euler": "k_euler",
	"heun": "k_heun",
	"lms": "k_lms",
	"plms": "plms"
}

static func _appears_valid(metadata:Dictionary):
	return metadata.has("parameters")

static func _dict_string_to_dict(str:String, key_delimiter:String = ":", space_delimiter:String = ",") -> Dictionary:
	var dict:Dictionary = {}
	if str == null:
		return dict

	for part in str.split(space_delimiter, false):
		var key_value:PackedStringArray = part.split(key_delimiter, false)
		if len(key_value) != 2:
			continue
		dict[key_value[0].strip_edges()] = key_value[1].strip_edges()

#	print(dict)
	return dict

static func _sanitize_for_shell(prompt_string:String) -> String:
	return prompt_string.replace("'", "\\'")

static func _get_configuration(automatic_sd_data:Dictionary) -> Dictionary:
	var configuration:Dictionary = {}
	var metadata_string:String = automatic_sd_data["parameters"]
	var lines:PackedStringArray = metadata_string.split("\n")

	var parameters_string:String = lines[-1]
	if not SimpleHelpers._string_contains_all(parameters_string, automatic_sd_keys):
		return configuration

	configuration = _dict_string_to_dict(parameters_string)
	if not configuration.has_all(automatic_sd_keys):
		printerr("[AUTOMATIC] [_get_configuration] Programming error")
		return {}

	var dimensions:PackedStringArray = configuration["Size"].split("x")
	if len(dimensions) < 2:
		printerr("[AUTOMATIC] [_get_configuration] Wrong dimensions")
		return {}

	var prompt:String = ""
	var negative_prompt:String = ""
	if len(lines) > 1:
		prompt = _sanitize_for_shell(lines[0])
	if len(lines) > 2:
		var second_line:String = _sanitize_for_shell(lines[-2])
		if second_line.begins_with("Negative prompt: "):
			negative_prompt = second_line.substr(len("Negative prompt: "))
			prompt += (" [" + negative_prompt + "]")

	var sampler_codename:String = configuration["Sampler"].to_lower()
	if sampler_name_to_code.has(sampler_codename):
		sampler_codename = sampler_name_to_code[sampler_codename]
	else:
		sampler_codename = sampler_codename.replace(" ", "_")

	configuration["Prompt"] = prompt
	configuration["Negative Prompt"] = negative_prompt
	configuration["Width"] = dimensions[0]
	configuration["Height"] = dimensions[1]
	configuration["Sampler"] = sampler_codename
	return configuration


static func build_command_line(automatic_sd_data:Dictionary) -> String:
	if not _appears_valid(automatic_sd_data):
		return ""

	var configuration:Dictionary = _get_configuration(automatic_sd_data)
	if configuration.is_empty():
		return ""

	var command_line:String = (
		"./dream.py" +
		" '{Prompt}'" +
		" -W{Width}" +
		" -H{Height}" +
		" --sampler {Sampler}" +
		" --cfg_scale {CFG scale}" +
		" --steps {Steps}" +
		" --seed {Seed}"
	).format(configuration)

	return command_line
