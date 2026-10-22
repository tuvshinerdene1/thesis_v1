extends Node
class_name FSMRunner

@export var character: GridCharacter
@export var grid_manager: GridManager

var states: Dictionary = {} # State name -> fsmstate resource
var current_state: FSMState = null
var is_running:bool = false

func load_fsm(state_list: Array[FSMState], start_state_name: String) -> void:
	states.clear()
	for state in state_list:
		states[state.state_name] = state
	
	if states.has(start_state_name):
		current_state = states[start_state_name]
	else:
		print("Error: Start state not found")
		
func start() -> void:
	if is_running or not current_state:
		return
	is_running = true
	_evaluate_current_state()

func _evaluate_current_state():
	if not is_running or not current_state:
		return
	print("Evaluating state: ", current_state.state_name)
	# Search through the state' srows from top to bottom
	var matched_rule: FSMRule = null
	for rule in current_state.rules:
		if _check_all_conditions(rule.conditions):
			matched_rule = rule
			break
	
	if matched_rule:
		# execute all actions in this row sequentially
		for action in matched_rule.actions:
			if not is_running:
				return
			await _execute_action(action)
			
			
		
		
		
func _check_all_conditions(conditions: Array[String]) -> bool:
	if conditions.is_empty():
		return true
	for cond in conditions:
		if not _evaluate_single_condition(cond):
			return false
	return true


func _evaluate_single_condition(condition: String) -> bool:
	var front_pos = character.get_front_grid_position()
	match condition:
		"front_is_tree":
			return grid_manager.is_tree_at(front_pos)
		"front_is_clear":
			return not grid_manager.is_tree_at(front_pos)
		"front_has_leaf":
			return grid_manager.has_leaf_at(front_pos)
		_:
			return false
