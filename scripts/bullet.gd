extends Area3D

## 优化后的子弹脚本
## 增加了调试信息和发射初期的安全期

@export var speed: float = 30.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var shooter: Node = null

func _ready() -> void:
	# 设置生命周期
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 检查当前是否已经重叠了物体
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func _physics_process(delta: float) -> void:
	# 持续飞行
	global_translate(-global_transform.basis.z * speed * delta)

func _on_body_entered(body: Node) -> void:
	handle_collision(body)

func _on_area_entered(area: Area3D) -> void:
	handle_collision(area)

func handle_collision(node: Node) -> void:
	# 过滤逻辑
	if node == shooter or (shooter and shooter.is_ancestor_of(node)):
		return
	if node.is_in_group("player"):
		return
	
	# 【调试信息】如果子弹还是消失，请查看编辑器下方的 Output/控制台
	print("子弹 [", name, "] 击中了: ", node.name, " (Group: ", node.get_groups(), ")")
		
	if node.has_method("take_damage"):
		node.take_damage(damage)
	
	queue_free()
