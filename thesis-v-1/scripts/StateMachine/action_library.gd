class_name  ActionLibrary
extends RefCounted

# Static helper or resource registry that returns a Callable for any action string
static func get_action_callable(action_name: String, character: GridCharacter, grid_manager: GridManager, runner: FSMRunner) -> Callable:
	match action_name:
		"move":
			return func():
				var front_pos = character.get_front_grid_position()
				if grid_manager.is_tree_at(front_pos):
					print("Hit a tree! Stopping.")
					runner.stop()
					return
				character.move_forward()
				await character.movement_finished
				
		"turn_left":
			return func():
				character.turn_left()
				await character.movement_finished
				
		"turn_right":
			return func():
				character.turn_right()
				await character.movement_finished
				
		_:
			return func():
				print("Unknown action: ", action_name)
