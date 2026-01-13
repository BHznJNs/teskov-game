extends Control

## 动态准星脚本
## 实现程序化绘制准星，并管理虚拟鼠标坐标以支持 MOUSE_MODE_CAPTURED

@export_group("Visual Settings")
@export var crosshair_color: Color = Color.WHITE
@export var outline_color: Color = Color.BLACK
@export var line_width: float = 4.0
@export var line_length: float = 20.0
@export var dot_size: float = 4.0
## 描边厚度
@export var outline_thickness: float = 3.0
@export var show_dot: bool = true
@export var draw_outline: bool = true

@export_group("Spread Settings")
## 基础散布偏移（像素，决定线条离中心的最小距离）
@export var base_spread: float = 16.0
## 当前实时散布（可由外部脚本根据后坐力调整）
@export var current_spread: float = 0.0

# 虚拟鼠标位置（相对于视口）
var virtual_mouse_pos: Vector2 = Vector2.ZERO
# 灵敏度（在捕获模式下使用）
var mouse_sensitivity: float = 1.0

func _ready() -> void:
	# 初始化虚拟鼠标位置为屏幕中心
	virtual_mouse_pos = get_viewport_rect().size / 2.0
	# 设置节点层级，确保准星在最上层
	z_index = 100
	# 允许处理输入
	set_process_input(true)
	# 准星节点不遮挡鼠标点击
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	# 处理 ESC 键释放鼠标
	if event.is_action_pressed("ui_cancel"): # 默认 Esc 是 ui_cancel
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	# 处理点击屏幕捕获鼠标
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				# 如果之前是可见模式，点击时可能需要校准虚拟位置到当前物理位置
				# virtual_mouse_pos = event.position 

	# 在捕获模式下累加位移
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			virtual_mouse_pos += event.relative * mouse_sensitivity
			# 限制在屏幕范围内
			var screen_size = get_viewport_rect().size
			virtual_mouse_pos.x = clamp(virtual_mouse_pos.x, 0, screen_size.x)
			virtual_mouse_pos.y = clamp(virtual_mouse_pos.y, 0, screen_size.y)
			# 请求重绘
			queue_redraw()
		else:
			# 非捕获模式下，虚拟位置跟随物理位置
			virtual_mouse_pos = event.position
			queue_redraw()

func _draw() -> void:
	var center = virtual_mouse_pos
	var spread_offset = base_spread + current_spread
	
	if draw_outline:
		var outline_width = line_width + (outline_thickness * 2.0)
		# 绘制描边 - 中心点
		if show_dot:
			draw_circle(center, dot_size + outline_thickness, outline_color)
		
		# 绘制描边 - 四个方向 (通过微调起点和终点，确保描边完整覆盖主线)
		var ext = outline_thickness
		# 上
		draw_line(center + Vector2(0, -spread_offset + ext), 
				  center + Vector2(0, -spread_offset - line_length - ext), 
				  outline_color, outline_width)
		# 下
		draw_line(center + Vector2(0, spread_offset - ext), 
				  center + Vector2(0, spread_offset + line_length + ext), 
				  outline_color, outline_width)
		# 左
		draw_line(center + Vector2(-spread_offset + ext, 0), 
				  center + Vector2(-spread_offset - line_length - ext, 0), 
				  outline_color, outline_width)
		# 右
		draw_line(center + Vector2(spread_offset - ext, 0), 
				  center + Vector2(spread_offset + line_length + ext, 0), 
				  outline_color, outline_width)

	# 绘制主颜色
	# 中心点
	if show_dot:
		draw_circle(center, dot_size, crosshair_color)
	
	# 绘制四个方向的线条
	# 上
	draw_line(center + Vector2(0, -spread_offset), 
			  center + Vector2(0, -spread_offset - line_length), 
			  crosshair_color, line_width)
	# 下
	draw_line(center + Vector2(0, spread_offset), 
			  center + Vector2(0, spread_offset + line_length), 
			  crosshair_color, line_width)
	# 左
	draw_line(center + Vector2(-spread_offset, 0), 
			  center + Vector2(-spread_offset - line_length, 0), 
			  crosshair_color, line_width)
	# 右
	draw_line(center + Vector2(spread_offset, 0), 
			  center + Vector2(spread_offset + line_length, 0), 
			  crosshair_color, line_width)

## 外部接口：获取当前准星的屏幕坐标（供射线检测使用）
func get_crosshair_screen_position() -> Vector2:
	return virtual_mouse_pos

## 外部接口：设置散布
func set_spread(value: float) -> void:
	current_spread = value
	queue_redraw()
