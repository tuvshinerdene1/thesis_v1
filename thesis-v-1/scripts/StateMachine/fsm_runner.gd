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
	# Search through the state's rows from top to bottom
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
		# handle state transition
		var next_name = matched_rule.target_state_name
		
		if next_name.to_lower() == "stop" or next_name.to_lower() == "exit":
			stop()
			return
		
		if next_name != "" and states.has(next_name):
			current_state = states[next_name]
		# if target_name is empty, it stays in the current state.
		
		# loop to evaluate the next state/step
		if is_running:
			_evaluate_current_state()
	else:
		print("fsm_runner.gd: No matching rules found in state: ", current_state.state_name)
		stop()
		
func _check_all_conditions(conditions: Array) -> bool:
	if conditions.is_empty():
		return true
	for cond in conditions:
		if not _evaluate_single_condition(str(cond)):
			return false
	return true

func _evaluate_single_condition(condition: String) -> bool:
	var condition_callable = ConditionLibrary.get_condition_callable(condition, character, grid_manager)
	return condition_callable.call()

func _execute_action(action:String) -> void:
	var action_callable = ActionLibrary.get_action_callable(action, character, grid_manager, self)
	await action_callable.call()

func stop() -> void:
	is_running = false
	print("FSM stopped.")
	
