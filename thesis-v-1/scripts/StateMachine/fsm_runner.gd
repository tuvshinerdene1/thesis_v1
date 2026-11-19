extends Node
class_name FSMRunner

#@export var character: GridCharacter
#@export var grid_manager: GridManager

var character: GridCharacter
var grid_manager: GridManager

var states: Dictionary = {} # State name -> FSMState resource
var current_state: FSMState = null
var is_running: bool = false

func load_fsm(state_list: Array[FSMState], start_state_name: String) -> void:
	stop()
	states.clear()
	for state in state_list:
		states[state.state_name] = state
	
	if states.has(start_state_name):
		current_state = states[start_state_name]
	else:
		current_state = null
		print("Error: Start state not found: ", start_state_name)

func start() -> void:
	if is_running or not current_state:
		return
	print("in fsm_runner.start()")
	is_running = true
	_evaluate_current_state()

func _evaluate_current_state() -> void:
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
		print("Matched rule found! Conditions: ", matched_rule.conditions, " | Actions: ", matched_rule.actions)
		
		# Execute all actions in this row sequentially
		for action in matched_rule.actions:
			if not is_running:
				return
			await _execute_action(action)
			if not is_running:
				return
		
		# Handle state transition
		var next_name := matched_rule.target_state_name.strip_edges()
		
		if next_name.to_lower() == "stop" or next_name.to_lower() == "exit":
			stop()
			return
		
		var target_state: FSMState = current_state
		if next_name != "":
			if states.has(next_name):
				target_state = states[next_name]
			else:
				print("Warning: Target state '", next_name, "' not found; staying in '", current_state.state_name, "'.")
		
		# Prevent an infinite zero-action self-loop
		if matched_rule.actions.is_empty() and target_state == current_state:
			print("Warning: Rule has no actions and loops on the same state; stopping to avoid infinite loop.")
			stop()
			return
		
		current_state = target_state
		
		# Loop to evaluate the next state/step
		if is_running:
			await get_tree().process_frame
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
	var condition_callable := ConditionLibrary.get_condition_callable(condition, character, grid_manager)
	if condition_callable.is_null():
		return false
	return condition_callable.call()

func _execute_action(action: String) -> void:
	print("Executing action: ", action)
	var action_callable := ActionLibrary.get_action_callable(action, character, grid_manager, self)
	
	if action_callable.is_null():
		print("ERROR: Action callable is null for action: ", action)
		return
		
	await action_callable.call()
	print("Finished action: ", action)

func stop() -> void:
	is_running = false
	print("FSM stopped.")
