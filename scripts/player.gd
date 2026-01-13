extends CharacterBody3D

## 玩家移动与瞄准脚本
## 实现 WASD 移动（相对于世界坐标系）与朝向目标点旋转

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 15.0
@export var friction: float = 10.0

@export_group("Rotation")
@export var rotation_speed: float = 10.0

@export_group("Equipment")
## 武器挂载点 (BoneAttachment3D)
@export var weapon_attachment: BoneAttachment3D
## 当前手持的模型实例
var current_weapon_instance: Node3D
## 子弹场景
@export var bullet_scene: PackedScene

@export_group("Inventory")
## 物品栏 (长度固定为 8)
@export var inventory: Array[Resource] = []
## 当前选中的索引
var selected_index: int = 0

## 物品切换信号
signal item_switched(index: int, item: Resource)

@export_group("Shooting")
## 射击冷却时间
@export var fire_rate: float = 0.2
var shoot_timer: float = 0.0

@export_group("FOV")
@export var fov_radius: float = 15.0
@export var fov_angle: float = 90.0 # 度数

# 存储当前瞄准的世界坐标位置
var target_look_at: Vector3 = Vector3.ZERO

@export var animation_player: AnimationPlayer

func _ready() -> void:
	# 将玩家添加到组，方便 UI 查找
	add_to_group("Player")
	
	# 确保物品栏有 8 个槽位
	if inventory.size() < 8:
		inventory.resize(8)
	
	# 初始选择第一个物品
	# 延迟一帧调用以确保所有节点已准备就绪
	call_deferred("switch_item", 0)
	
	# 如果 UI 已经存在，同步所有槽位
	var hotbar = get_tree().get_first_node_in_group("Hotbar")
	if hotbar and hotbar.has_method("sync_all_slots"):
		hotbar.sync_all_slots(inventory)

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_rotation(delta)
	handle_animation()
	
	if shoot_timer > 0:
		shoot_timer -= delta

func _input(event: InputEvent) -> void:
	# 直接检测数字键 1-8 切换物品
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var index = event.keycode - KEY_1
			switch_item(index)
			return

	# 检测射击输入 (鼠标左键)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 只有在鼠标被捕获模式下才允许射击（避免点击 UI 或切换窗口时射击）
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				# 检查当前物品是否是武器
				var current_item = inventory[selected_index]
				# 使用 get() 避开可能的类识别问题
				if current_item and current_item.get("item_type") == 0: # 0 对应 ItemType.WEAPON
					shoot()

## 切换物品逻辑
func switch_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
		
	selected_index = index
	var item = inventory[index]
	
	# 移除旧模型
	if current_weapon_instance:
		current_weapon_instance.queue_free()
		current_weapon_instance = null
	
	# 实例化新模型
	if item and item.model_scene and weapon_attachment:
		current_weapon_instance = item.model_scene.instantiate()
		weapon_attachment.add_child(current_weapon_instance)
		
	# 发出信号通知 UI
	item_switched.emit(selected_index, item)

## 处理射击逻辑
func shoot() -> void:
	if shoot_timer > 0 or not bullet_scene:
		return
	
	# 检查是否有当前手持的模型
	if not current_weapon_instance:
		return
		
	# 查找枪口位置
	var muzzle = current_weapon_instance.find_child("Muzzle", true)
	if not muzzle:
		muzzle = current_weapon_instance
		
	# 播放射击动画
	if animation_player and animation_player.has_animation("holding-right-shoot"):
		# 使用 Blend/OneShot 更好，但这里先简单播放
		# 注意：这里可能会打断移动动画，建议在编辑器中使用 AnimationTree 优化
		animation_player.play("holding-right-shoot")
		# 0.5秒后切回原来的动画逻辑由 handle_animation 在下一帧处理（如果不是循环动画）
	
	# 实例化子弹
	var bullet = bullet_scene.instantiate()
	
	# 设置发射者，防止子弹刚出生就撞到自己
	if "shooter" in bullet:
		bullet.set("shooter", self)
		
	# 将子弹添加到场景树（通常添加到根节点或专门的子弹容器，避免随玩家移动）
	get_tree().root.add_child(bullet)
	
	# 设置子弹初始位置和朝向
	bullet.global_position = muzzle.global_position
	
	# 计算子弹朝向：看向目标点
	# 确保目标点与枪口在同一水平高度，实现水平射击
	var horizontal_target = Vector3(target_look_at.x, muzzle.global_position.y, target_look_at.z)
	
	# 如果目标点离枪口太近，直接使用枪口的朝向
	if bullet.global_position.distance_to(horizontal_target) > 0.1:
		bullet.look_at(horizontal_target)
	else:
		bullet.global_transform.basis = muzzle.global_transform.basis
	
	# 设置冷却
	shoot_timer = fire_rate

## 处理动画状态
func handle_animation() -> void:
	if not animation_player:
		return
		
	var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
	
	if horizontal_velocity.length() > 0.1:
		var is_sprinting = Input.is_key_pressed(KEY_SHIFT)
		
		if is_sprinting and animation_player.has_animation("sprint"):
			if animation_player.current_animation != "sprint":
				animation_player.play("sprint", 0.2)
		elif animation_player.has_animation("walk") and animation_player.current_animation != "walk":
			animation_player.play("walk", 0.2)
	else:
		if animation_player.has_animation("idle") and animation_player.current_animation != "idle":
			animation_player.play("idle", 0.2)

## 处理 WASD 移动
func handle_movement(delta: float) -> void:
	# 获取输入向量 (Project Settings -> Input Map 中需要配置 move_left, move_right, move_forward, move_backward)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# 计算世界坐标系下的移动方向
	# 注意：在 Godot 3D 中，-Z 是前方，+Z 是后方，-X 是左方，+X 是右方
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction != Vector3.ZERO:
		# 检查是否按住 Shift 奔跑
		var target_speed = walk_speed
		if Input.is_key_pressed(KEY_SHIFT):
			target_speed = sprint_speed
			
		# 加速移动
		velocity.x = lerp(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, acceleration * delta)
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
