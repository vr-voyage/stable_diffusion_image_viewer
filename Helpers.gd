extends Node

class_name SimpleHelpers

static func _string_contains_all(string_data:String, all_substrings:PackedStringArray) -> bool:
	for substring in all_substrings:
		if not string_data.contains(substring):
			return false
	return true
