extends Node3D

## 摄像机控制脚本
## 实现等距视角跟随与鼠标 3D 射线检测

@export_group("Target")
@export var target: Node3D  # 玩家节点
@export var follow_speed: float = 5.0

@export_group("Camera Settings")
@export var offset: Vector3 = Vector3(10, 10, 10)  # 默认等距视角偏移
@export var look_at_offset: Vector3 = Vector3.ZERO

@onready var camera: Camera3D = $Camera3D
@onready var fov_overlay: MeshInstance3D = get_tree().get_first_node_in_group("fov_overlay")

func _ready() -> void:
	# 初始化摄像机位置与角度
	if target:
		global_position = target.global_position + offset
	
	# 确保摄像机看向目标
	look_at_target()

func _process(delta: float) -> void:
	if not target:
		return
		
	# 平滑跟随目标
	var target_pos = target.global_position + offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# 更新玩家的瞄准位置
	update_player_aiming()
	# 更新视野着色器
	update_fov_shader()

func look_at_target() -> void:
	if target:
		camera.look_at(target.global_position + look_at_offset, Vector3.UP)

## 获取鼠标在 3D 空间中的位置（通过射线检测）
func get_mouse_3d_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# 创建射线查询
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
	# 包含所有静态碰撞体（默认层）
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_query)
	
	if result:
		return result.position
	else:
		# 如果没有碰撞到任何物体，则返回射线与 Y=0 平面的交点
		var plane = Plane(Vector3.UP, 0)
		var intersection = plane.intersects_ray(ray_origin, ray_direction)
		if intersection:
			return intersection
		return Vector3.ZERO

## 将鼠标位置传递给玩家脚本
func update_player_aiming() -> void:
	if target and target.has_method("update_target_look_at"):
		var mouse_3d = get_mouse_3d_position()
		target.update_target_look_at(mouse_3d)

## 更新视野着色器参数
func update_fov_shader() -> void:
	if not fov_overlay or not target:
		return
		
	var mat = fov_overlay.get_surface_override_material(0) as ShaderMaterial
	if not mat:
		return
		
	var fov_data = target.get_fov_data()
	mat.set_shader_parameter("player_pos", fov_data.position)
	mat.set_shader_parameter("player_forward", fov_data.forward)
	mat.set_shader_parameter("fov_radius", fov_data.radius)
	mat.set_shader_parameter("fov_angle", deg_to_rad(fov_data.angle))
