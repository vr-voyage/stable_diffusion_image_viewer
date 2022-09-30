extends Node

class_name PNGHelper

const PNG_SIGNATURE:int = 0x474E5089
const BINARY_MODE_ON:int = 0x0A1A0A0D

static func _read_u32_big_endian(data:PackedByteArray, index:int) -> int:
	return (data[index] << 24) | (data[index+1] << 16) | (data[index+2] << 8) | (data[index+3] << 0)

static func is_valid_png_header(png_header:PackedByteArray) -> bool:
	if png_header.decode_u32(0) != PNG_SIGNATURE:
		printerr("Invalid PNG signature")
		return false
	if png_header.decode_u32(4) != BINARY_MODE_ON:
		printerr("PNG file not opened in binary mode")
		return false
	return true

static func _chunk_metadata_data_start(chunk_data:PackedByteArray, key_end:int, type:String):
	var cursor:int = key_end
	var last_index:int = len(chunk_data) - 1
	match type:
		"tEXt":
			for i in range(cursor, len(chunk_data)):
				if chunk_data[i] != 0:
					return i
			return -1
		"iTXt":
			# Skip 3 zero
			cursor += 3
			cursor = min(cursor, last_index)
#			print("iTxt cursor : %d" % [cursor])

			# Skip lang
			cursor = chunk_data.find(0, cursor)
			if cursor < 0:
				return cursor

			cursor += 1
			cursor = min(cursor, last_index)

			# Skip UTF-8 key
#			print("iTxt cursor : %d" % [cursor])
			cursor = chunk_data.find(0, cursor)
			if cursor < 0:
				return cursor

			cursor += 1
			cursor = min(cursor, last_index)

			if cursor == last_index:
				return -1

			return cursor

static func _parse_metadata_chunk(chunk_data:PackedByteArray, database:Dictionary, type:String) -> bool:
	var key_name_start:int = 0
	# Looking for next NULL character
	var key_name_stop:int = chunk_data.find(0, key_name_start)
	if key_name_stop == key_name_start:
		printerr("Empty key name")
		return false

	var data_start:int = _chunk_metadata_data_start(chunk_data, key_name_stop, type)
	if data_start < 0:
		printerr("Reach end of the chunk before getting any data")
		return false

	var key_name:String = chunk_data.slice(key_name_start, key_name_stop).get_string_from_utf8()
	var data_content:String = chunk_data.slice(data_start).get_string_from_utf8()

	if key_name.is_empty() or data_content.is_empty():
		printerr("Empty key name or content : [%s] = %s" % [key_name, data_content])
		return false

	database[key_name] = data_content
	return true

static func _parse_chunk(png_data:PackedByteArray, cursor:int, data:Dictionary) -> int:
	var _start:int = cursor
	if len(png_data) <= cursor + 16:
		return -ERR_INVALID_DATA
	var length:int = _read_u32_big_endian(png_data, cursor)
	cursor += 4
	var type:String = png_data.slice(cursor, cursor+4).get_string_from_ascii()
	cursor += 4

	var chunk_data:PackedByteArray = png_data.slice(cursor, cursor+length)
	cursor += length

	var _crc:int = png_data.decode_u32(cursor)
	cursor += 4

#	print("[_parse_chunk] Cursor at : 0x%08d, Chunk : Type %s - Length : %d" % [cursor, type, length])

	match type:
		"tEXt", "iTXt":
			_parse_metadata_chunk(chunk_data, data, type)
	
	return cursor

static func get_metadata(png_data:PackedByteArray) -> Dictionary:
	var dict:Dictionary = {}
	get_metadata_to(png_data, dict)
	return dict

static func get_metadata_to(png_data:PackedByteArray, out_dictionary:Dictionary) -> int:
	if not is_valid_png_header(png_data):
		return ERR_INVALID_DATA

	var cursor:int = 8
	var data_length:int = len(png_data)
	while cursor >= 0 and cursor < data_length:
		cursor = _parse_chunk(png_data, cursor, out_dictionary)
	return OK
