# fsm_editor.gd
extends Control

signal fsm_executed(states: Array[FSMState], start_state_name: String)


@export var fsm_runner: FSMRunner
@export var game_world: Node3D


var states: Array[FSMState] = []
var selected_state_index: int = -1
var start_state_name = ""

@onready var state_item_list: ItemList = $HBoxContainer/LeftPanel/StateItemList
@onready var rules_row_container: VBoxContainer = $HBoxContainer/RightPanel/ScrollContainer/RulesRowContainer

@onready var play_button: Button = $PlayButton
@onready var add_state_button: Button = $HBoxContainer/LeftPanel/HBoxContainer/AddButton
@onready var delete_state_button: Button = $HBoxContainer/LeftPanel/HBoxContainer/DeleteButton
@onready var set_start_button: Button =  $HBoxContainer/LeftPanel/HBoxContainer/SetAsStartButton
@onready var add_rule_button: Button = $HBoxContainer/RightPanel/AddRuleButton

@onready var rename_state_input: LineEdit = $HBoxContainer/LeftPanel/HBoxContainer2/LineEdit
@onready var rename_state_button: Button = $HBoxContainer/LeftPanel/HBoxContainer2/Button

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	add_state_button.pressed.connect(_on_add_state_pressed)
	delete_state_button.pressed.connect(_on_delete_state_pressed)
	set_start_button.pressed.connect(_on_set_start_state_pressed)
	add_rule_button.pressed.connect(_on_add_rule_pressed)
	state_item_list.item_selected.connect(_on_state_item_selected)
	rename_state_button.pressed.connect(_on_rename_state_pressed)
	rename_state_input.text_submitted.connect(func(_new_text: String):
		_on_rename_state_pressed()
	)


func _on_play_pressed() -> void:
	if states.is_empty():
		print("error: no states were found")
		return

	if start_state_name == "":
		print("error: no start state was set")
		return

	print("Sending fsm data to level script")
	if not states[0].rules.is_empty():
		states[0].rules[0].printRule()
	fsm_executed.emit(states, start_state_name)
	

# create state
func _on_add_state_pressed() -> void:
	var new_state = FSMState.new()
	new_state.state_name = "State_" + str(states.size() + 1)
	states.append(new_state)
	_refresh_state_list()

## delete state
#func _on_delete_state_pressed() -> void:
	#if selected_state_index < 0 or selected_state_index >= states.size():
		#return
	#states.remove_at(selected_state_index)
	#selected_state_index = -1
	#_refresh_state_list()
	#for child in rules_row_container.get_children():
		#child.queue_free()

# refresh state ui
func _refresh_state_list() -> void:
	print("refreshed state list")
	state_item_list.clear()
	for i in range (states.size()):
		var state = states[i]
		var display_text = state.state_name
		if state.state_name == start_state_name:
			display_text += " (Start)"
		state_item_list.add_item(display_text)

func _on_state_item_selected(index: int) -> void:
	selected_state_index = index
	rename_state_input.text = states[index].state_name
	_populate_rule_editor(states[index])

func _on_delete_state_pressed() -> void:
	if selected_state_index < 0 or selected_state_index >= states.size():
		return
	var deleted_name := states[selected_state_index].state_name
	if start_state_name == deleted_name:
		start_state_name = ""
	states.remove_at(selected_state_index)
	selected_state_index = -1
	rename_state_input.text = ""
	_refresh_state_list()
	for child in rules_row_container.get_children():
		child.queue_free()
func _populate_rule_editor(state:FSMState) -> void:
	for child in rules_row_container.get_children():
		child.queue_free()
	
	for i in range(state.rules.size()):
		var rule = state.rules[i]
		_create_rule_row_ui(rule, i)
		
func _create_rule_row_ui(rule: FSMRule, rule_index: int) -> void:
	var row_hbox = HBoxContainer.new()

	# Guarantee at least 1 condition clause per rule
	var all_conditions = ConditionLibrary.get_all_conditions()
	if rule.conditions.is_empty():
		var initial_clause = ConditionClause.new()
		initial_clause.condition_id = all_conditions[0] if not all_conditions.is_empty() else "always"
		rule.conditions.append(initial_clause)

	# --- 1. Conditions stack (1 or more clauses connected by AND / OR) ---
	var conds_box = VBoxContainer.new()

	for c_idx in range(rule.conditions.size()):
		var clause: ConditionClause = rule.conditions[c_idx]
		var clause_row = HBoxContainer.new()

		# Negation toggle button ("NOT")
		var not_btn = Button.new()
		not_btn.toggle_mode = true
		not_btn.button_pressed = clause.negated
		not_btn.text = "NOT" if clause.negated else "IS"
		not_btn.tooltip_text = "Negate condition (NOT)"
		not_btn.toggled.connect(func(pressed: bool):
			clause.negated = pressed
			not_btn.text = "NOT" if pressed else "IS"
		)
		clause_row.add_child(not_btn)

		# Condition dropdown
		var cond_button = OptionButton.new()
		for cond in all_conditions:
			cond_button.add_item(cond)

		var cond_idx := all_conditions.find(clause.condition_id)
		if cond_idx == -1 and not all_conditions.is_empty():
			cond_idx = 0
			clause.condition_id = all_conditions[0]
		if cond_idx != -1:
			cond_button.select(cond_idx)

		cond_button.item_selected.connect(func(idx: int):
			clause.condition_id = cond_button.get_item_text(idx)
		)
		clause_row.add_child(cond_button)

		# Remove condition button (only enabled when > 1 condition exists)
		var remove_cond_btn = Button.new()
		remove_cond_btn.text = "-"
		remove_cond_btn.disabled = rule.conditions.size() <= 1
		remove_cond_btn.tooltip_text = "At least 1 condition is required" if rule.conditions.size() <= 1 else "Remove condition"
		remove_cond_btn.pressed.connect(func():
			if rule.conditions.size() > 1:
				rule.conditions.remove_at(c_idx)
				_populate_rule_editor(states[selected_state_index])
		)
		clause_row.add_child(remove_cond_btn)

		conds_box.add_child(clause_row)

		# Logic connector ("AND" / "OR") between this clause and the next clause
		if c_idx < rule.conditions.size() - 1:
			var logic_btn = Button.new()
			var current_logic := clause.logic_with_next.to_upper()
			if current_logic != "AND" and current_logic != "OR":
				current_logic = "AND"
				clause.logic_with_next = "AND"
			logic_btn.text = current_logic
			logic_btn.tooltip_text = "Click to toggle AND / OR"
			logic_btn.pressed.connect(func():
				clause.logic_with_next = "OR" if clause.logic_with_next.to_upper() == "AND" else "AND"
				logic_btn.text = clause.logic_with_next
			)
			conds_box.add_child(logic_btn)

	var add_cond_btn = Button.new()
	add_cond_btn.text = "+ Cond"
	add_cond_btn.pressed.connect(func():
		var extra = ConditionClause.new()
		extra.condition_id = all_conditions[0] if not all_conditions.is_empty() else "always"
		extra.negated = false
		extra.logic_with_next = "AND"
		rule.conditions.append(extra)
		_populate_rule_editor(states[selected_state_index])
	)
	conds_box.add_child(add_cond_btn)
	row_hbox.add_child(conds_box)

	# --- 2. Actions stack (0, 1, or many actions) ---
	var actions_box = VBoxContainer.new()
	var all_actions = ActionLibrary.get_all_actions()

	for a_idx in range(rule.actions.size()):
		var act_row = HBoxContainer.new()
		var act_btn = OptionButton.new()
		for action in all_actions:
			act_btn.add_item(action)

		var current_act := str(rule.actions[a_idx])
		var act_sel := all_actions.find(current_act)
		if act_sel == -1 and not all_actions.is_empty():
			act_sel = 0
			rule.actions[a_idx] = all_actions[0]
		if act_sel != -1:
			act_btn.select(act_sel)

		var captured_a_idx := a_idx
		act_btn.item_selected.connect(func(idx: int):
			rule.actions[captured_a_idx] = act_btn.get_item_text(idx)
		)
		act_row.add_child(act_btn)

		var remove_act_btn = Button.new()
		remove_act_btn.text = "-"
		remove_act_btn.pressed.connect(func():
			rule.actions.remove_at(captured_a_idx)
			_populate_rule_editor(states[selected_state_index])
		)
		act_row.add_child(remove_act_btn)

		actions_box.add_child(act_row)

	var add_act_btn = Button.new()
	add_act_btn.text = "+ Action"
	add_act_btn.pressed.connect(func():
		if not all_actions.is_empty():
			rule.actions.append(all_actions[0])
			_populate_rule_editor(states[selected_state_index])
	)
	actions_box.add_child(add_act_btn)
	row_hbox.add_child(actions_box)

	# --- 3. Target state dropdown ---
	var target_button = OptionButton.new()
	target_button.add_item("Loop Current")
	target_button.add_item("Stop")
	for s in states:
		target_button.add_item(s.state_name)

	if rule.target_state_name == "Stop":
		target_button.select(1)
	elif rule.target_state_name == "":
		target_button.select(0)
	else:
		var found_idx := 0
		for i in range(2, target_button.get_item_count()):
			if target_button.get_item_text(i) == rule.target_state_name:
				found_idx = i
				break
		target_button.select(found_idx)

	target_button.item_selected.connect(func(idx: int):
		var txt = target_button.get_item_text(idx)
		if txt == "Loop Current":
			rule.target_state_name = ""
		elif txt == "Stop":
			rule.target_state_name = "Stop"
		else:
			rule.target_state_name = txt
	)
	row_hbox.add_child(target_button)

	# --- 4. Delete entire rule row ---
	var delete_btn = Button.new()
	delete_btn.text = "X"
	delete_btn.pressed.connect(func():
		if selected_state_index >= 0 and selected_state_index < states.size():
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
func _on_rename_state_pressed() -> void:
	if selected_state_index < 0 or selected_state_index >= states.size():
		return

	var new_name := rename_state_input.text.strip_edges()
	if new_name.is_empty():
		print("Error: State name cannot be empty.")
		rename_state_input.text = states[selected_state_index].state_name
		return

	# Prevent duplicate state names
	for i in range(states.size()):
		if i != selected_state_index and states[i].state_name == new_name:
			print("Error: A state named '", new_name, "' already exists.")
			return

	var state := states[selected_state_index]
	var old_name := state.state_name
	if old_name == new_name:
		return

	state.state_name = new_name

	# 1. Update start state reference if needed
	if start_state_name == old_name:
		start_state_name = new_name

	# 2. Update target_state_name in all rules across all states
	for s in states:
		for rule in s.rules:
			if rule.target_state_name == old_name:
				rule.target_state_name = new_name

	rename_state_input.text = new_name

	# 3. Refresh list & keep current state selected + rule dropdowns updated
	_refresh_state_list()
	state_item_list.select(selected_state_index)
	_populate_rule_editor(state)
