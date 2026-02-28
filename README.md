# bazi_core

一个功能强大的 Dart/Flutter 八字（BaZi）计算库，支持真太阳时、早晚子时配置、农历/阳历转换、十神计算、长生十二神、以及完善的刑冲合害自动判定系统。

## 功能特性

- **排盘基础**: 八字（四柱）计算、真太阳时支持、早晚子时配置、农历/阳历互转。
- **十神系统**: 支持计算干支相对于日主的十神关系。
- **大运/小运**: 起运时间精准计算（精确到秒），支持流年、小运。
- **刑冲合害**: 全面支持天干五合、地支六合、三合局、三会局、三刑、六冲、六害、相绝、暗合等复杂关系的自动判定。
- **高级算法**: 自动处理“争合”、“多冲一”及“大局压制小局”等专业命理逻辑。
- **旬空判定**: 支持获取干支所在旬的空亡地支。

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  bazi_core: ^0.3.0
  sxwnl_spa_dart: ^0.10.1
```

## 快速开始

### 1. 从阳历时间创建八字

```dart
import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final solarTime = AstroDateTime(2026, 2, 18, 12, 0);
  final chart = BaziChart.createBySolarDate(clockTime: solarTime);
  
  print('八字: ${chart.bazi}');
}
```

### 2. 计算刑冲合害 (干支关系)

```dart
// 获取原局内部所有刑冲合害
final results = chart.getAllInteractions();

for (var res in results) {
  print('[${res.type}] 参与位置: ${res.nodes}');
}
```

### 3. 计算大运与小运

```dart
final fortune = Fortune.createByBaziChart(chart);

// 获取前 8 步大运
for (int i = 1; i <= 8; i++) {
  final decade = fortune.getDecadeByIndex(i);
  print('第$i步大运: ${decade.ganZhi} (${decade.startAge}-${decade.endAge}岁)');
}
```

## API 文档

### BaziChart (主控类)

| 方法/属性 | 说明 |
|------|------|
| `createBySolarDate(...)` | 通过阳历时间创建八字盘。可选位置、时区、早晚子时等。 |
| `createByLunarDate(...)` | 通过农历时间创建八字盘。 |
| `getAllInteractions(...)` | 获取原局的所有刑冲合害。支持传入 `enabledTypes` 过滤。 |
| `getInteractionsWith(...)` | 获取原局与岁运组合后的关系。 |
| `bazi` | `BaZi` 对象，包含年、月、日、时柱。 |

### BaziTable (底层属性与判定)

这是一个静态工具类，提供极速的干支属性查询。

| 静态方法 | 说明 |
|------|------|
| `getWuXingOfGan(gan)` | 获取天干五行。 |
| `getWuXingOfZhi(zhi)` | 获取地支五行。 |
| `getCangGan(zhi)` | 获取地支藏干列表（按本、中、余气排序）。 |
| `getYinYangOfGan(gan)` | 获取天干阴阳。 |
| `getLifeStage(gan, zhi)` | 计算天干在某地支的生命状态（长生十二神）。 |
| `isStemClash(a, b)` | 判定天干相冲。 |
| `isBranchClash(a, b)` | 判定地支六冲。 |

### Relationship (十神计算)

| 静态方法 | 说明 |
|------|------|
| `getShiShen(dayMaster, target)` | 计算目标天干相对于日主的十神。 |
| `getCangGanShiShen(dm, zhi)` | 计算目标地支所有藏干相对于日主的十神列表。 |

### Fortune & Decade (大运系统)

- **Fortune**: 包含 `qiYunTime` (起运时间), `startAge` (起运年龄), `daYunBase` (起始柱)。
- **Decade**: 包含 `ganZhi` (大运干支), `startAge` / `endAge` (虚岁区间), `startTime` / `endTime` (时间区间)。

### Interaction Models (结果模型)

- **InteractionNode**: 包装了 `pillar` (位置标记) 和 `value` (干或支)。
- **InteractionResult**: 包含 `type` (关系类型), `nodes` (参与节点列表), `combinedWuXing` (合化结果)。

## 许可证

本项目采用 MIT 许可证。
