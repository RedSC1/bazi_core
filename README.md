# bazi_core

[![Pub Version](https://img.shields.io/pub/v/bazi_core)](https://pub.dev/packages/bazi_core)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

一个功能强大的 Dart/Flutter 八字（四柱）命理计算核心库。

本项目旨在提供一套标准、精准的八字基础排盘与分析引擎，支持真太阳时、早晚子时配置、农历/阳历互相转换、十神计算、长生十二神状态获取，以及完善的干支刑冲合害（15种复杂关系）自动判定系统。

## ✨ 核心特性

- **🕒 基础排盘与历法**
  - 精准转换公历（阳历）与农历。
  - 支持真太阳时计算，包含经度时差调整。
  - 支持灵活配置早子时与晚子时。
- **☯️ 十神与神煞**
  - 自动计算天干地支相对于日主的十神关系（如正官、偏财等）。
  - 支持智能计算长生十二神起运。
  - 提供旬空（空亡）地支判定。
- **🔮 岁运系统（大运/流年/流月）**
  - 精确推算起运交运时间。
  - 一键计算指定步数的大运、指定年龄的流年干支。
  - 支持基于“五虎遁”的流月干支自动推演。
- **⚔️ 刑冲合害高级解析系统**
  - 全面涵盖原局及岁运互动中的 **15 种底层组合关系**：
    - **天干**: 五合、四冲。
    - **地支**: 六合、三合局、半合、拱合、三会局、六冲、六害、六破、相绝、暗合。
    - **相刑**: 三刑全、相刑、自刑。
  - 内置高级命理算法：精准处理“争合”、“多冲一”及“大局压制小局”等专业分析逻辑。

## 📦 安装

在你的项目 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  bazi_core: ^0.4.3
  sxwnl_spa_dart: ^0.10.2 # 由于底层时间与历法依赖于该核心库，通常需要一并引入
```

然后执行命令获取包：
```bash
flutter pub get
# 或是纯 Dart 项目：
dart pub get
```

## 🚀 快速开始

### 1. 创建基础八字排盘

使用公历时间进行排盘并打印出四柱：

```dart
import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 定义排盘起止时间点：2026年2月18日 12:00
  final solarTime = AstroDateTime(2026, 2, 18, 12, 0);
  
  // 创建八字盘实例
  final chart = BaziChart.createBySolarDate(clockTime: solarTime);
  
  // 打印具体的四柱八字组合
  print('八字: ${chart.bazi}'); // 输出结构示例：丙午 庚寅 癸酉 戊午
}
```

### 2. 解析干支互动关系（刑冲合害）

通过引擎自动解析八字原局内部存在的所有复杂互动关系。

```dart
// 获取原局内部所有刑冲合害集合
final results = chart.getAllInteractions();

for (var res in results) {
  // 打印每个关系的类型及其作用的位置
  // 例如日志可能会输出: [branchCombination] 参与柱: [Month, Day]
  print('[${res.type}] 参与柱: ${res.nodes}');
}
```

### 3. 推演岁运轨迹（大运与流年）

利用八字盘生成对应的岁运大运系统，轻松查询关键年份信息：

```dart
// 建立全局岁运系统
final fortune = Fortune.createByBaziChart(chart);

print('起运年龄: ${fortune.startAge} 岁');
print('精准交运时间: ${fortune.qiYunTime}');

// 获取第 1 步大运（通常索引 0 表示原局，索引 1 为第一步运），包含它辖下的10个流年
final decade = fortune.getDecadeByIndex(1);
print('第一步大运干支: ${decade.ganZhi}');

// 遍历输出该大运包含的流年轨迹
for (var fy in decade.flowYears) {
  print('年份: ${fy.year}，干支: ${fy.ganZhi}');
}
```

## 📖 API 核心类概览

### BaziChart (八字排盘主体)

| 核心方法 / 属性 | 类型 | 说明 |
|------|------|------|
| `BaziChart.createBySolarDate` | `factory` | 通过公历构建八字盘，支持传递经度和进行早晚子时逻辑调整。 |
| `BaziChart.createByLunarDate` | `factory` | 通过农历构建八字基础盘。 |
| `getAllInteractions` | `Method` | 解析并返回八字原局内自有的刑冲合害组列表。 |
| `getInteractionsWith` | `Method` | 以原局作为基础，加入外部元素（如大运/流年），生成全套干支互动关系。 |
| `bazi` | `BaZi` | 返回核心 `BaZi` 对象，即包裹了年、月、日、时四柱结构。 |
| `lunarDate` | `LunarDate`| 解析此八字对应的底层精准农历日期数据。 |

### BaZi & GanZhi (核心数据层)

- **BaZi (四柱)**: 分别包裹 `year`, `month`, `day`, `time` 四个独立节点。
- **GanZhi (干支)**: 涵盖 `gan` (天干) 和 `zhi` (地支)；内置了方便的算数符（比如 `+` 运算符）解决简单的六十甲子顺逆推演。

### Fortune & Decade (大运岁运引擎)

- **Fortune (岁运总控制)**:
  - 属性 `qiYunTime` 能够精准推算出交运起点的日期。
  - 函数 `getDecadeByIndex(index)` 提供按步数快速调取大运段的方法。
  - 函数 `getFlowYearByAge(age)` 支持输入实岁查询特定的流年数据。
- **Decade (单步大运包装)**:
  - 内部属性包括当属大运的 `ganZhi`（天干地支），以及其所涵盖的十个年度包装对象 `flowYears`。

### 相关算法支持及互动判定枚举

覆盖判定: `stemCombination` (五合), `stemClash` (四冲), `branchTripleCombination` (三合全), `branchHalfCombination` (半合局), `branchArchingCombination` (拱合), `branchTripleDirection` (三会), `branchClash` (六冲), `branchCombination` (六合), `branchHarm` (六害), `branchDestruction` (相破), `branchTriplePunishment` (三刑全), `branchPunishment` (相刑), `branchSelfPunishment` (自刑), `branchHiddenCombination` (暗合), `branchSeverance` (相绝)。

## 🧪 实验性功能：神煞分析

> ⚠️ **注意**：本功能代码由 AI 辅助录入，目前包含多种常见神煞（如天乙贵人、驿马、桃花、魁罡等）。
> 虽然经过初步测试，但尚未进行大规模人工校验，可能存在遗漏或判定偏差。请谨慎用于生产环境，并欢迎提交 PR 修正。

### 功能特点
- **全盘扫描**：支持原局四柱（年/月/日/时）的神煞检测。
- **岁运集成**：支持大运、流年、流月、流日、流时的神煞分析。
- **复杂规则**：涵盖整柱匹配（如魁罡）、干查支（如天乙）、支查支（如桃花）、季节/纳音相关（如天赦、月德）等多种规则。

### 使用示例

```dart
import 'package:bazi_core/bazi_core.dart';

// 1. 创建八字排盘
final chart = BaziChart.createBySolarDate(
  clockTime: AstroDateTime(2024, 1, 1, 12, 0, 0),
);

// 2. 准备岁运干支 (可选)
final daYun = GanZhi.fromName('庚辰');
final liuNian = GanZhi.fromName('辛巳');

// 3. 执行分析
final info = ShenShaHelper.analyze(
  chart,
  daYun: daYun,
  liuNian: liuNian,
  // 也可以传入流月/流日/流时
);

// 4. 查看结果
print('年柱神煞: ${info.yearShenSha}');
print('日柱神煞: ${info.dayShenSha}');
print('流年神煞: ${info.liuNianShenSha}');
```

## 🤝 参与贡献

欢迎大家提交 Issue 和 Pull Request 来帮助扩展和健壮它！
如果您是对八字排盘底层算法或命理交互逻辑有研究的专家，也极其期待能与您进行深入交流。

## 📄 许可证

本项目开源发布基于 [MIT License](LICENSE) 许可证发布。
