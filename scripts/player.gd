extends CharacterBody3D

## 玩家移动与瞄准脚本
## 实现 WASD 移动（相对于世界坐标系）与朝向目标点旋转

@export_group("Movement")
@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 10.0

@export_group("Rotation")
@export var rotation_speed: float = 10.0

@export_group("FOV")
@export var fov_radius: float = 15.0
@export var fov_angle: float = 90.0 # 度数

# 存储当前瞄准的世界坐标位置
var target_look_at: Vector3 = Vector3.ZERO

@export var animation_player: AnimationPlayer

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)
	handle_animation()

## 处理动画状态
func handle_animation() -> void:
	if not animation_player:
		return
		
	# 根据移动速度决定播放哪个动画
	# 使用 horizontal velocity 忽略垂直速度（如跳跃/下落）
	var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
	
	if horizontal_velocity.length() > 0.1:
		if animation_player.current_animation != "walk":
			animation_player.play("walk", 0.2) # 0.2s 混合时间，使切换更平滑
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle", 0.2)

## 处理 WASD 移动
func handle_movement(delta: float) -> void:
	# 获取输入向量 (Project Settings -> Input Map 中需要配置 move_left, move_right, move_forward, move_backward)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# 计算世界坐标系下的移动方向
	# 注意：在 Godot 3D 中，-Z 是前方，+Z 是后方，-X 是左方，+X 是右方
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction != Vector3.ZERO:
		# 加速移动
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
	else:
		# 摩擦力减速
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
	
	# 应用重力（如果需要）
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	move_and_slide()

## 处理角色旋转，使其朝向 target_look_at
func handle_rotation(delta: float) -> void:
	# 确保目标点与玩家在同一高度，避免角色倾斜
	var look_target := Vector3(target_look_at.x, global_position.y, target_look_at.z)
	
	# 如果目标点离玩家太近，不进行旋转以避免抖动
	if global_position.distance_to(look_target) > 0.1:
		# 计算目标旋转
		var target_transform := global_transform.looking_at(look_target, Vector3.UP)
		# 平滑插值旋转
		global_transform.basis = global_transform.basis.slerp(target_transform.basis, rotation_speed * delta)

## 外部接口：更新瞄准位置
func update_target_look_at(pos: Vector3) -> void:
	target_look_at = pos

## 获取视野数据
func get_fov_data() -> Dictionary:
	return {
		"position": global_position,
		"forward": -global_transform.basis.z, # CharacterBody3D 默认正面是 -Z
		"radius": fov_radius,
		"angle": fov_angle
	}
