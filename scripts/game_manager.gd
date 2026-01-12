extends Node

## 游戏管理器 (Autoload)
## 处理场景切换、撤离逻辑与全局状态

signal zone_changed(new_zone_name: String)
signal extraction_started(duration: float)
signal extraction_failed
signal extraction_successful

var current_zone: String = "Base"
var is_extracting: bool = false
var extraction_timer: SceneTreeTimer

## 切换场景接口
func switch_to_zone(zone_path: String) -> void:
	# 实际开发中这里会调用 get_tree().change_scene_to_file(zone_path)
	print("Switching to zone: ", zone_path)
	current_zone = zone_path.get_file().get_basename()
	zone_changed.emit(current_zone)

## 开始撤离逻辑
func start_extraction(duration: float = 4.0) -> void:
	if is_extracting:
		return
		
	is_extracting = true
	extraction_started.emit(duration)
	print("Extraction started, wait for ", duration, " seconds...")
	
	extraction_timer = get_tree().create_timer(duration)
	extraction_timer.timeout.connect(_on_extraction_timeout)

func cancel_extraction() -> void:
	if not is_extracting:
		return
	
	is_extracting = false
	extraction_failed.emit()
	print("Extraction cancelled.")

func _on_extraction_timeout() -> void:
	if is_extracting:
		is_extracting = false
		extraction_successful.emit()
		print("Extraction successful! Returning to base.")
		# 返回基地场景
		switch_to_zone("res://scenes/base.tscn")

## 玩家死亡处理
func handle_player_death() -> void:
	print("Player died! Dropping loot and returning to base.")
	# 这里可以添加掉落逻辑
	switch_to_zone("res://scenes/base.tscn")
