extends Resource
class_name InventoryItem

## 物品资源类
## 定义物品的基础数据和属性

enum ItemType {
	WEAPON,   # 武器
	FOOD,     # 食物
	MEDICINE, # 药品
	UTILITY   # 工具/物资
}

@export var item_name: String = "新物品"
@export var item_type: ItemType = ItemType.WEAPON
@export var icon: Texture2D
## 物品对应的 3D 模型场景
@export var model_scene: PackedScene

## 物品的基础属性（例如攻击力、回复量等，可在此扩展）
@export var properties: Dictionary = {}
