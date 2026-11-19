class_name ConditionLibrary
extends RefCounted

static func get_all_conditions() -> Array[String]:
	return [
		"front_is_tree",
		"front_has_leaf",
		"left_is_tree",
		"right_is_tree",
		"always"
	]

static func get_condition_callable(condition_name: String, character: GridCharacter, grid_manager: GridManager) -> Callable:
	match condition_name:
		"always":
			return func() -> bool:
				return true

		"front_is_tree":
			return func() -> bool:
				return grid_manager.is_tree_at(character.get_front_grid_position())

		"front_has_leaf":
			return func() -> bool:
				return grid_manager.has_leaf_at(character.get_front_grid_position())

		"left_is_tree":
			return func() -> bool:
				return grid_manager.is_tree_at(character.get_left_grid_position())

		"right_is_tree":
			return func() -> bool:
				return grid_manager.is_tree_at(character.get_right_grid_position())

		_:
			return func() -> bool:
				print("Unknown condition: ", condition_name)
				return false
