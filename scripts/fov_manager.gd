extends Node

## FOV 管理器
## 负责协调视野逻辑，更新物体的可见性

@export var player: CharacterBody3D
@export var update_interval: float = 0.1 # 每 0.1 秒更新一次逻辑，优化性能

var visible_objects: Array = []
var time_since_last_update: float = 0.0

func _ready() -> void:
	# 如果没有手动指定玩家，尝试在场景中查找
	if not player:
		player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if not player:
		return
		
	time_since_last_update += delta
	if time_since_last_update >= update_interval:
		time_since_last_update = 0.0
		update_visibility()

func register_object(obj: Node) -> void:
	if not visible_objects.has(obj):
		visible_objects.append(obj)

func unregister_object(obj: Node) -> void:
	visible_objects.erase(obj)

func update_visibility() -> void:
	var fov_data = player.get_fov_data()
	
	for obj in visible_objects:
		if obj.has_method("check_visibility"):
			obj.check_visibility(fov_data)

## 更新着色器参数（通常由 CameraController 或 FOVOverlay 调用）
func get_shader_params() -> Dictionary:
	if not player:
		return {}
	var fov_data = player.get_fov_data()
	return {
		"player_pos": fov_data.position,
		"player_forward": fov_data.forward,
		"fov_radius": fov_data.radius,
		"fov_angle": deg_to_rad(fov_data.angle)
	}
