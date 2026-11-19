class_name ConditionClause
extends Resource

@export var condition_id: String = "front_is_clear"
@export var negated: bool = false
@export var logic_with_next: String = "AND" # "AND" or "OR" (used when another clause follows)
