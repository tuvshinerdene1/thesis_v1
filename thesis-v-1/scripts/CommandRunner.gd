extends Node
class_name  CommandRunner
@export var character: GridCharacter
@export var grid_manager: GridManager

var is_running: bool = false
var command_queue: Array[String] = []
var instruction_pointer: int = 0

# load a sequence of program to execute 
func load_program(commands: Array[String]):
	command_queue = commands
	instruction_pointer = 0
	
func run_program():
	if is_running or command_queue.is_empty():
		return
	is_running = true
	_execute_next_instruction()

func _execute_next_instruction():
	if instruction_pointer >= command_queue.size():
		stop_program()
		return
	var cmd = command_queue[instruction_pointer]
	instruction_pointer += 1
	
	match cmd:
		"move":
			var front_pos = character.get_front_grid_position()
			if grid_manager.is_tree_at(front_pos):
				print("hit a tree!")
				stop_program()
				return
			character.move_forward()
			await character.movement_finished
		"turn_left":
			character.turn_left()
			await character.movement_finished
		"turn_right":
			character.turn_right()
			await character.movement_finished
		_:
			print("unknown command: ", cmd)
	if is_running:
		_execute_next_instruction()

func stop_program():
	is_running = false
	instruction_pointer = 0
	print("Program finished or stopped.")
		
