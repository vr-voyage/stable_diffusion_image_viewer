extends Node

class_name StableDiffusionDataVoyage

const _voyage_metadata_keys:Array[String] = [
	"AI_Generator",
	"AI_Prompt",
	"AI_StableDiffusion_Guidance_Scale",
	"AI_StableDiffusion_Inferences",
	"AI_Custom_Deterministic",
	"AI_Torch_Seed"
]

static func _is_deterministic(voyage_sd_data:Dictionary) -> bool:
	return voyage_sd_data["AI_Custom_Deterministic"].to_lower() == "true"

static func appears_valid(metadata:Dictionary) -> bool:
	return metadata.has_all(_voyage_metadata_keys)

static func build_command_line(voyage_sd_data:Dictionary) -> String:
	if not appears_valid(voyage_sd_data):
		return ""

	# I could almost one-line this, but the Prompt has to be put insides
	# single-quotes, since terminals will interpret a LOT of things inside
	# double-quoted strings (Like $PWD or $(ls -rf $HOME/*))
	var prompt:String = voyage_sd_data["AI_Prompt"].replace("'", "\\'")
	var base_command_line:String = "./txt2img.py --prompt '" + prompt + "'"
	var command_line:String = base_command_line + (
		" --plms"+
		" --n_iter {AI_StableDiffusion_Inferences}"+
		" --scale {AI_StableDiffusion_Guidance_Scale}"
	).format(voyage_sd_data)

	if _is_deterministic(voyage_sd_data):
		command_line += (" --seed %s" % voyage_sd_data["AI_Torch_Seed"])

#	print(command_line)
	return command_line
