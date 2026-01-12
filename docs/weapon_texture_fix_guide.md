# 枪械贴图修复指南

## 问题描述

导入的 GLB 枪械模型缺少贴图，显示为纯白色或灰色。

## 原因分析

GLB 文件中的材质引用了外部贴图文件（`colormap.png`），但 Godot 导入时无法自动找到正确的贴图路径。

## 解决方案

### 方案 1：在 Godot 编辑器中手动重新分配贴图（推荐）

1. **打开场景**：在 Godot 编辑器中打开 [`scenes/player.tscn`](../scenes/player.tscn)

2. **选择武器节点**：在场景树中找到并选择 `Player -> character-male-a -> character-male-a -> Skeleton3D -> RightHandAttachment -> blaster-a`

3. **查看材质**：
   - 在右侧的检查器（Inspector）中，展开 `MeshInstance3D` 部分
   - 找到 `Material` 属性，应该能看到一个材质

4. **编辑材质**：
   - 点击材质旁边的下拉箭头，选择 "Edit" 或直接点击材质
   - 在材质的 `Albedo` 部分，找到 `Texture` 属性
   - 点击 `Texture` 右侧的文件夹图标或空白区域

5. **分配贴图**：
   - 在弹出的文件选择器中，导航到 `res://assets/models/weapons/Textures/`
   - 选择 `colormap.png` 文件
   - 点击 "打开" 或 "Open"

6. **保存场景**：按 `Ctrl+S` 保存场景

### 方案 2：重新导入 GLB 文件时设置材质

1. **删除现有的 GLB 导入文件**：
   - 找到 [`assets/models/weapons/blaster-a.glb`](../assets/models/weapons/blaster-a.glb)
   - 删除对应的 `.import` 文件（如果存在）

2. **配置导入设置**：
   - 在 Godot 文件系统中选择 `blaster-a.glb`
   - 在 Import 面板中，确保材质设置正确
   - 点击 "Reimport"

3. **手动分配贴图**（如果自动导入失败）：参考方案 1

### 方案 3：创建自定义材质

如果上述方法都不起作用，可以创建一个新的 StandardMaterial3D：

1. **创建新材质**：
   - 在文件系统中右键点击 `assets/models/weapons/` 目录
   - 选择 "新建资源" -> "StandardMaterial3D"
   - 命名为 `weapon_material.tres`

2. **配置材质**：
   - 双击打开新创建的材质
   - 在 `Albedo` 部分，点击 `Texture` 并选择 `colormap.png`
   - 可以根据需要调整其他属性（如 Metallic、Roughness 等）

3. **应用材质**：
   - 选择武器的 MeshInstance3D 节点
   - 将新创建的材质拖拽到 `Material Override` 属性上

## 验证

运行游戏后，枪械应该显示正确的彩色贴图，而不是纯白色或灰色。

## 其他枪械模型

如果需要为其他枪械模型（如 `blaster-b.glb`、`blaster-c.glb` 等）设置贴图，重复上述相同的步骤。所有枪械模型都使用相同的贴图文件 `colormap.png`。

## 常见问题

**Q: 贴图文件在哪里？**
A: 贴图文件应该在 [`assets/models/weapons/Textures/colormap.png`](../assets/models/weapons/Textures/colormap.png)

**Q: 为什么导入时没有自动应用贴图？**
A: GLB 文件中的贴图路径是相对于原始文件位置的，移动文件后路径会失效，需要手动重新分配。

**Q: 可以使用其他贴图吗？**
A: 可以，Kenney 资产包中可能包含不同的贴图变体（如 `variation-a.png`），你可以尝试使用它们来获得不同的视觉效果。
