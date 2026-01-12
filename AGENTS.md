## 项目目标

使用 Godot 制作一个 3D 的 PC 游戏，需要实现一套“双摇杆射击（Twin-Stick Shooter）”风格的移动与瞄准系统：
1.  **移动控制**：使用 **WASD** 键控制移动（角色应相对于屏幕/世界坐标系移动，而不是基于角色朝向移动）。
2.  **瞄准控制**：角色应始终**朝向鼠标光标**的位置。
3.  **3D 坐标转换**：请从摄像机向地平面发射**射线（Raycast）**，以此计算出鼠标在 3D 空间中的具体位置，用于控制角色的旋转。

这是一个“搜打撤”类型的射击游戏，即角色需要从基地__进入危险区域__（通常是在基地的某个位置有个传送点可以直接切换场景到危险区域），危险区域中有各种的房子和树林，玩家可以到房子中搜寻物资，物资通常有以下几种用途：1. 用于在玩家受击扣血后进行治疗，2. 用于给玩家补充水分和能量，3. 用于战斗（即枪械和弹药），4. 无实际用途，物资可以在玩家回到基地后卖出，换取货币。玩家进入危险区域后无法随意回到基地，需要到达指定地点后等待 4 秒才能被传送回基地。
游戏为 PVPVE，即在危险区域内有玩家、其他玩家和人机。玩家在战斗中被击杀后会直接被传送回基地，物品会丢失（可被其它玩家拾取）。

## Godot 开发规则

1.  **Engine Version**: This project uses **Godot 4.3** (or your version). strictly adhere to GDScript 2.0 syntax.
	- Use `@export`, `@onready`.
	- `Twens` are created via `create_tween()`.
	- Signal connections: `signal_name.connect(callable)`.

2.  **File Safety**: 
	- **NEVER** edit `.tscn` or `.tres` files directly unless specifically asked. These are binary/text hybrids managed by the Godot Editor. Editing them manually usually corrupts them.
	- Only edit `.gd` (scripts) and `.gdshader` files.

3.  **Code Style**:
	- Use static typing where possible (e.g., `var health: int = 100`) for better autocomplete and AI context understanding.
	- Prefer code-based solutions for logic (e.g., creating Timers in code) over relying on Scene Tree nodes usually configured in the editor, unless it's visual.

4.  **Workflow**:
    - If a new node is needed in the scene, instruct the user to add it in the Godot Editor, tell them specifically what node type and what name to give it, then write the script to attach to it.
