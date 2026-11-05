class_name FSMRule
extends Resource

@export var conditions: Array = []
@export var actions: Array = []
@export var target_state_name: String = "" # if left empty or matches current, it loops

func printRule():
	print("conditions: ", conditions)
	print("actions: ", actions)
	print("target_state_name: ", target_state_name)
