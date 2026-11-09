extends Node

@export_category("NPC Prefabs")
@export var NPC_1_Scene : PackedScene
@export var NPC_2_Scene : PackedScene
@export var NPC_3_Scene : PackedScene
@export var NPC_4_Scene : PackedScene

@export_category("Config")
@export var spawn_point : Node3D
@export var spawn_node : Node3D

func _ready() -> void:
	Signals.create_npc_1.connect(_crear_npc_1)
	Signals.create_npc_2.connect(_crear_npc_2)
	Signals.create_npc_3.connect(_crear_npc_3)
	Signals.create_npc_4.connect(_crear_npc_4)
	Signals.create_Random.connect(_crear_random)
	
	
func _crear_npc_1() -> void :
	print("_crear_1")
	if NPC_1_Scene != null:
		var npc_1 : Node3D = NPC_1_Scene.instantiate()
		spawn_node.get_tree().root.add_child(npc_1)
		npc_1.global_position = spawn_point.global_position
	pass
	
func _crear_npc_2() -> void :
	print("_crear_2")
	if NPC_2_Scene != null:
		var npc_2 : Node3D = NPC_2_Scene.instantiate()
		spawn_node.get_tree().root.add_child(npc_2)
		npc_2.global_position = spawn_point.global_position
	pass
	
func _crear_npc_3() -> void :
	print("_crear_lighting")
	if NPC_3_Scene != null:
		var npc_lighting : Node3D = NPC_3_Scene.instantiate()
		spawn_node.get_tree().root.add_child(npc_lighting)
		npc_lighting.global_position = spawn_point.global_position
	
func _crear_npc_4() -> void :
	print("_crear_poison")
	if NPC_4_Scene != null:
		var npc_3 : Node3D = NPC_4_Scene.instantiate()
		spawn_node.get_tree().root.add_child(npc_3)
		npc_3.global_position = spawn_point.global_position
	
func _crear_random() -> void :
	print("random:")
	var random : int = randi_range(1,5)
	match random:
		1:
			_crear_npc_1()
		2:
			_crear_npc_2()
		3:
			_crear_npc_3()
		4:
			_crear_npc_4()
	pass
