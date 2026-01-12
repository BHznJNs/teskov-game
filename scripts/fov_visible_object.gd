extends Node3D

## 物体可见性控制脚本
## 挂载到敌人、物资等需要视野检测的物体上

@export var check_occlusion: bool = true
@export var target_node: Node3D # 实际控制可见性的节点，默认为自身

var fov_manager: Node

func _ready() -> void:
	if not target_node:
		target_node = self
		
	# 查找场景中的 FOVManager
	fov_manager = get_tree().get_first_node_in_group("fov_manager")
	if fov_manager:
		fov_manager.register_object(self)
	else:
		# 如果没找到，可能是还没加载，延迟注册
		call_deferred("_deferred_register")

func _deferred_register() -> void:
	fov_manager = get_tree().get_first_node_in_group("fov_manager")
	if fov_manager:
		fov_manager.register_object(self)

func _exit_tree() -> void:
	if fov_manager:
		fov_manager.unregister_object(self)

## 由 FOVManager 调用
func check_visibility(fov_data: Dictionary) -> void:
	var player_pos = fov_data.position
	var player_forward = fov_data.forward
	var radius = fov_data.radius
	var angle_deg = fov_data.angle
	
	var to_obj = global_position - player_pos
	var dist = to_obj.length()
	
	# 1. 距离检测
	if dist > radius:
		target_node.visible = false
		return
		
	# 2. 角度检测
	var to_obj_flat = Vector3(to_obj.x, 0, to_obj.z).normalized()
	var forward_flat = Vector3(player_forward.x, 0, player_forward.z).normalized()
	var angle_to_obj = rad_to_deg(acos(forward_flat.dot(to_obj_flat)))
	
	if angle_to_obj > angle_deg * 0.5:
		target_node.visible = false
		return
		
	# 3. 射线遮挡检测
	if check_occlusion:
		if not has_line_of_sight(player_pos):
			target_node.visible = false
			return
			
	# 全部通过，设为可见
	target_node.visible = true

func has_line_of_sight(player_pos: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	# 从玩家位置向物体中心发射射线
	# 注意：射线起点稍微抬高一点，避免碰到地面
	var start = player_pos + Vector3.UP * 0.5
	var end = global_position + Vector3.UP * 0.5
	
	var query = PhysicsRayQueryParameters3D.create(start, end)
	# 排除玩家自身（如果需要）
	# query.exclude = [...] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# 如果碰撞到的不是物体自身，说明被遮挡了
		# 这里假设物体有碰撞体，且射线应该能碰到它
		var collider = result.collider
		if collider != self and not is_ancestor_of(collider) and collider != get_parent():
			return false
			
	return true
