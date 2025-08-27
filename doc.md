# 绳结3D App 设计文档

## 项目概述
基于200种绳结数据和3D动画技术，开发一款绳结学习App，适配iOS、iPad、macOS系统。

## 产品方案讨论记录

### 第一轮讨论（2025-08-27）

#### 用户需求
- 拥有200种绳结的分类数据（JSON格式）
- 已实现3D动画组件 SpriteKitAnimationView
- 希望创建简单实用的绳结学习App
- 不需要复杂功能（AR模式、播放速度控制等）

### 第二轮讨论（2025-08-27）

#### 需求更新
- 重新定义4个Tab：用途分类、绳结类型、收藏、设置
- 前3个Tab使用统一UI界面，只是数据源不同
- 用途分类从 `knots_data.json` 获取 `type: "category"` 数据
- 绳结类型从 `knots_data.json` 获取 `type: "type"` 数据  
- 所有绳结数据临时使用 `all_knots_data.json`
- 前3个Tab都支持搜索功能（name和desc字段）
- 设置页面包含语言切换、隐私协议、版本信息

#### 点击交互流程
- 前3个Tab的item点击后跳转到绳结详情页
- 详情页主要展示 `all_knots_data.json` 中的 `details` 字段内容
- 集成3D动画展示（SpriteKitAnimationView）

#### 多语言支持
- 支持中文和英文，默认中文
- JSON数据暂不做多语言处理
- UI字符串全部支持多语言
- 设置页面可切换语言

#### 数据基础
- **绳结数量**：200种绳结
- **用途分类**：16个分类
  - Essential Knots、Arborist、Boating、Camping、Caving、Climbing
  - Decorative、Diving、Fire & Rescue、Fishing、Military、Necktie
  - Pioneering、Scouting、Storage、Theatre & Film
- **类型分类**：8种类型
  - Bends、Binding、Hitches、Lashings、Loops、Multi-Loop、Stoppers、Whipping
- **数据格式**：JSON + 对应图片资源
- **动画系统**：已实现，支持3D展示、360度旋转、镜像翻转

## 最终App架构设计

### 底部Tab栏结构（4个Tab）

#### 1. 📂 用途分类 (Categories)
**功能定位**：按用途浏览绳结
- 数据源：`knots_data.json` 中 `type: "category"` 的16项
- 展示内容：Essential Knots, Arborist, Boating, Camping, Caving, Climbing, Decorative, Diving, Fire & Rescue, Fishing, Military, Necktie, Pioneering, Scouting, Storage, Theatre & Film
- 支持搜索：根据name和desc字段搜索

#### 2. 🔧 绳结类型 (Types)
**功能定位**：按技术类型浏览绳结
- 数据源：`knots_data.json` 中 `type: "type"` 的8项
- 展示内容：Bends, Binding, Hitches, Lashings, Loops, Multi-Loop, Stoppers, Whipping
- 支持搜索：根据name和desc字段搜索

#### 3. ❤️ 收藏 (Favorites)
**功能定位**：用户个人收藏管理
- 显示用户收藏的绳结列表
- UI界面与前两个Tab保持一致
- 支持搜索：在收藏的绳结中搜索

#### 4. ⚙️ 设置 (Settings)
**功能定位**：应用配置和信息
- 语言切换功能
- 隐私协议
- 版本信息
- 其他应用设置

## 技术实现基础

### 现有资源优势
- ✅ 完整的绳结数据和分类体系
- ✅ 成熟的3D动画组件实现
- ✅ 支持多平台（iOS、iPad、macOS）
- ✅ 离线数据支持

### 核心技术栈
- **UI框架**：SwiftUI（主要），UIKit（辅助）
- **动画引擎**：SpriteKit
- **项目管理**：XcodeGen
- **数据格式**：JSON + 本地图片资源

### 数据结构分析

#### knots_data.json
```json
[
  { "type": "category", "name": "Essential Knots", "desc": "How to tie 18 essential knots.", "image": "essential_knots.jpg" },
  { "type": "type", "name": "Bends", "desc": "How to tie a bend.", "image": "bends.jpg" }
]
```

#### all_knots_data.json  
```json
{
  "totalKnots": 94,
  "knots": [
    {
      "id": "munter",
      "name": "Munter Hitch", 
      "description": "Friction hitch for controlled descent...",
      "classification": {
        "type": ["Hitches"],
        "foundIn": ["Arborist", "Climbing", ...]
      }
    }
  ]
}
```

### 多语言实现

#### 本地化文件结构
```
knots3d/
├── Resources/
│   └── locale/
│       ├── zh-Hans.lproj/
│       │   └── Localizable.strings (中文)
│       └── en.lproj/
│           └── Localizable.strings (英文)
└── LocalizationHelper.swift (本地化管理)
```

#### 使用方式
```swift
// 方式1：直接使用
Text("tab_categories".localized)

// 方式2：使用预定义常量
Text(LocalizedStrings.TabBar.categories)

// 方式3：带参数的本地化
Text("search_results_count".localized(with: 5))
```

#### 语言管理
- `LanguageManager` 单例管理当前语言
- `LocalizationHelper` 负责从locale目录加载本地化文件
- 支持运行时切换语言
- 自动保存用户语言偏好
- Bundle缓存机制提升性能

## 开发优先级
1. **Phase 1**：基础UI框架搭建（Tab栏、统一列表界面、多语言支持）
2. **Phase 2**：数据加载和展示（knots_data.json解析）
3. **Phase 3**：搜索功能实现（name和desc字段搜索）
4. **Phase 4**：收藏功能和设置页面
5. **Phase 5**：3D动画学习模块集成

## 绳结详情页设计

### 页面结构
1. **标题区域**
   - 绳结名称
   - 别名 (alsoKnownAs)
   - 简短描述

2. **3D动画区域**
   - 集成 SpriteKitAnimationView 组件
   - 支持播放、暂停、镜像、360度查看

3. **详情信息卡片**（基于details字段）
   - 🎯 **用途** (usage) - 必显示
   - 📚 **历史** (history) - 条件显示
   - 🔧 **结构** (structure) - 条件显示
   - ⚡ **强度可靠性** (strengthReliability) - 条件显示
   - 📖 **ABOK编号** (abok) - 条件显示
   - ⚠️ **注意事项** (note) - 条件显示

4. **相关绳结区域**
   - 展示 related 数组中的相关绳结
   - 点击可跳转到对应绳结详情页

5. **分类信息**
   - 类型：classification.type
   - 应用领域：classification.foundIn

### 交互流程
- **用途分类** → 分类列表 → 绳结列表 → 绳结详情
- **绳结类型** → 类型列表 → 绳结列表 → 绳结详情  
- **收藏** → 绳结列表 → 绳结详情

## 设计原则
- **简单易用**：避免复杂的功能和控制
- **内容为王**：专注于绳结知识的有效传达
- **性能优化**：充分利用现有组件和数据结构
- **多平台适配**：确保在不同设备上的良好体验

---
*文档创建时间：2025-08-27*
*最后更新：2025-08-27*