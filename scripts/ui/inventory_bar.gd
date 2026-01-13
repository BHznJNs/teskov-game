extends Control

## 物品栏 UI 脚本
## 动态生成 8 个槽位并监听玩家切换信号

@export var slot_count: int = 8
@export var slot_size: Vector2 = Vector2(64, 64)
@export var spacing: int = 10
@export var highlight_color: Color = Color.YELLOW
@export var normal_color: Color = Color(0.2, 0.2, 0.2, 0.8)

var slots: Array[Panel] = []
var active_highlight: Panel

func _ready() -> void:
	# 确保父节点覆盖全屏，以便内部组件能正确居中对齐
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 鼠标穿透，避免遮挡 3D 场景点击
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	
	# 添加到组，方便玩家同步
	add_to_group("Hotbar")
	
	setup_slots()
	
	# 查找玩家并连接信号
	# 假设玩家在 "Player" 组中
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.item_switched.connect(_on_player_item_switched)

func setup_slots() -> void:
	# 创建水平容器
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", spacing)
	add_child(hbox)
	
	# 设置锚点为底部中心
	hbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	
	# 调整偏移以确保可见并留出边距
	hbox.offset_bottom = -20
	hbox.offset_top = -20 - slot_size.y
	
	# 关键：设置生长方向，使其从中心向两边扩展，防止左偏
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	for i in range(slot_count):
		var slot = Panel.new()
		slot.custom_minimum_size = slot_size
		
		# 设置背景样式
		var style = StyleBoxFlat.new()
		style.bg_color = normal_color
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.GRAY
		slot.add_theme_stylebox_override("panel", style)
		
		# 添加数字标识
		var label = Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_right = -5
		label.offset_bottom = -2
		label.add_theme_font_size_override("font_size", 12)
		slot.add_child(label)
		
		# 添加图标显示容器
		var icon_rect = TextureRect.new()
		icon_rect.name = "Icon"
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = 5
		icon_rect.offset_top = 5
		icon_rect.offset_right = -5
		icon_rect.offset_bottom = -5
		slot.add_child(icon_rect)
		
		hbox.add_child(slot)
		slots.append(slot)

func _on_player_item_switched(index: int, item: Resource) -> void:
	# 更新所有槽位的高亮
	for i in range(slots.size()):
		var slot = slots[i]
		var style = slot.get_theme_stylebox("panel") as StyleBoxFlat
		if i == index:
			style.border_color = highlight_color
			style.bg_color = normal_color.lightened(0.1)
		else:
			style.border_color = Color.GRAY
			style.bg_color = normal_color
			
		# 更新图标 (如果有)
		var icon_rect = slot.get_node("Icon") as TextureRect
		if i == index and item:
			if "icon" in item and item.icon:
				icon_rect.texture = item.icon
			else:
				icon_rect.texture = null
		# 注意：这里逻辑上我们可能希望所有槽位都显示图标，而不仅仅是选中的。
		# 但是由于 item 参数只传递了当前切换的，我们需要在初始化时或之后同步所有物品。
		# 为了演示，我们目前只在切换时更新当前槽位。
		
		# 修正：如果玩家有物品列表，我们可以遍历更新。
		# 但信号目前只传递了切换后的结果。

## 外部接口：全量同步 UI（可选）
func sync_all_slots(inventory: Array) -> void:
	for i in range(min(slots.size(), inventory.size())):
		var item = inventory[i]
		var icon_rect = slots[i].get_node("Icon") as TextureRect
		if item and "icon" in item:
			icon_rect.texture = item.icon
		else:
			icon_rect.texture = null
