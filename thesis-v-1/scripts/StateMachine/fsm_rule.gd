class_name FSMRule
extends Resource

@export var conditions: Array[ConditionClause] = []
@export var actions: Array[String] = []
@export var target_state_name: String = ""
func printRule():
	print("conditions: ", conditions)
	print("actions: ", actions)
	print("target_state_name: ", target_state_name)
