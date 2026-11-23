class_name KarmaEventDef
extends Resource

@export var id: StringName = &""
## "sin", "fate", or "both"
@export var bar: String = "sin"
@export var threshold: int = 30
@export var weight: float = 1.0
@export var cost: float = 15.0
## "spawn_npc", "spawn_hostiles", "steal_chest", "open_secret_realm", "grant_recipe", "tame_beast"
@export var kind: String = "spawn_npc"
@export var params: Dictionary = {}
