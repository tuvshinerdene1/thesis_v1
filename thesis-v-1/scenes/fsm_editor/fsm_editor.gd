extends Control

@export var fsm_runner: FSMRunner
@export var game_world: Node3D


var states: Array[FSMState] = []
var selected_state_index: int = -1
var start_state_name = ""

@onready var state_item_list: ItemList = $HBoxContainer/LeftPanel/StateItemList
@onready var rules_row_container: VBoxContainer = $HBoxContainer/RightPanel/ScrollContainer/RulesRowContainer
@onready var play_button: Button = $HBoxContainer/PlayButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	# validation checks
	if states.is_empty():
		print("Error: Cannot play. No states created!")
		return
	if start_state_name == "":
		print("Error: Cannot play. Start state not set!")
		return
	print("Starting FSM with start state: ", start_state_name)
	
	self.visible = false
	
	fsm_runner.load_fsm(states, start_state_name)
	fsm_runner.start()

# create state
func _on_add_state_pressed() -> void:
	var new_state = FSMState.new()
	new_state.state_name = "State_" + str(states.size() + 1)
	states.append(new_state)
	_refresh_state_list()

# delete state
func _on_delete_state_pressed() -> void:
	if selected_state_index < 0 or selected_state_index >= states.size():
		return
	states.remove_at(selected_state_index)
	selected_state_index = -1
	_refresh_state_list()
	for child in rules_row_container.get_children():
		child.queue_free()

# refresh state ui
func _refresh_state_list() -> void:
	state_item_list.clear()
	for i in range (states.size()):
		var state = states[i]
		var display_text = state.state_name
		if state.state_name == start_state_name:
			display_text += " (Start)"
		state_item_list.add_item(display_text)

func _on_state_item_selected(index: int) -> void:
	selected_state_index = index
	_populate_rule_editor(states[index])

func _populate_rule_editor(state:FSMState) -> void:
	for child in rules_row_container.get_children():
		child.queue_free()
	
	for i in range(state.rules.size()):
		var rule = state.rules[i]
		_create_rule_row_ui(rule, i)
		
func _create_rule_row_ui(rule:FSMRule, rule_index: int) -> void:
	var row_hbox = HBoxContainer.new()
	
	# condition dropdown
	var cond_button = OptionButton.new()
	var all_conditions = ConditionLibrary.get_all_conditions()
	for cond in all_conditions:
		cond_button.add_item(cond)
	
	if not rule.conditions.is_empty():
		var current_cond = str(rule.conditions[0])
		var idx = all_conditions.find(current_cond)
		if idx != -1:
			cond_button.select(idx)
	
	# set selected based on rule.conditions...
	cond_button.item_selected.connect(func(idx):
		rule.conditions = [cond_button.get_item_text(idx)]
	)
	row_hbox.add_child(cond_button)
	
	# action dropdown
	var action_button = OptionButton.new()
	var all_actions = ActionLibrary.get_all_actions()
	for action in all_actions:
		action_button.add_item(action)
	
	if not rule.actions.is_empty():
		var current_action = str(rule.actions[0])
		var idx = all_actions.find(current_action)
		if idx != -1:
			action_button.select(idx)
			
	action_button.item_selected.connect(func(idx):
		rule.actions = [action_button.get_item_text(idx)]	
	)
	row_hbox.add_child(action_button)
	
	# target state dropdown (or stop)
	var target_button = OptionButton.new()
	target_button.add_item("Loop Current")
	target_button.add_item("Stop")
	for s in states:
		target_button.add_item(s.state_name)
	
	## pre-select target state 
	if rule.target_state_name == "Stop":
		target_button.select(1)
	elif rule.target_state_name == "":
		target_button.select(0)
	else:
		for i in range(2, target_button.get_item_count()):
			if target_button.get_item_text(i) == rule.target_state_name:
				target_button.select(i)
				break
				
	target_button.item_selected.connect(func(idx):
		var txt = target_button.get_item_text(idx)
		if txt == "Loop Current":
			rule.target_state_name = ""
		elif txt == "Stop":
			rule.target_state_name = "Stop"
		else:
			rule.target_state_name = txt

	)
	row_hbox.add_child(target_button)
	
	# delete row button
	var delete_btn = Button.new()
	delete_btn.text = "X"
	delete_btn.pressed.connect(func():
		states[selected_state_index].rules.remove_at(rule_index)
		_populate_rule_editor(states[selected_state_index])
	)
	row_hbox.add_child(delete_btn)
	
	rules_row_container.add_child(row_hbox)
	
func _on_add_rule_pressed() -> void:
	if selected_state_index < 0:
		return
	var new_rule = FSMRule.new()
	states[selected_state_index].rules.append(new_rule)
	_populate_rule_editor(states[selected_state_index])

func _on_set_start_state_pressed() -> void:
	if selected_state_index < 0:
		return
	start_state_name = states[selected_state_index].state_name
	_refresh_state_list()	
	
	
