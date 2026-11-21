# level1_refactored.gd
extends BaseLevel


func _ready() -> void:
	if level_data == null:
		level_data = _build_default_level_2_data()
	super._ready()


func _build_default_level_2_data() -> LevelData:
	var data := LevelData.new()
	data.level_name = "Level 2"
	data.start_position = Vector2i(1, 1)
	data.start_direction = GridCharacter.Direction.EAST
	data.grid_data = [
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 3, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	]
	return data
