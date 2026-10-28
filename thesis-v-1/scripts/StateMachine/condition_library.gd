class_name ConditionLibrary
extends RefCounted

static func get_all_conditions() -> Array[String]:
	return [
		"front_is_clear",
		"front_is_tree",
		"front_has_leaf"
	]

static func get_condition_callable(condition_name: String, character: GridCharacter, grid_manager: GridManager) -> Callable:
	var front_pos = character.get_front_grid_position()
	
	match condition_name:
		"front_is_tree":
			return func() -> bool:
				return grid_manager.is_tree_at(front_pos)
				
		"front_is_clear":
			return func() -> bool:
				return not grid_manager.is_tree_at(front_pos)
				
		"front_has_leaf":
			return func() -> bool:
				return grid_manager.has_leaf_at(front_pos)
				
		_:
			return func() -> bool:
				print("Unknown condition: ", condition_name)
				return false
