
# bazi_core

一个功能强大的 Dart/Flutter 八字（BaZi）计算库，支持真太阳时、早晚子时配置、农历/阳历转换等功能。

## 功能特性

- 八字（四柱）计算
- 支持真太阳时计算
- 支持早晚子时配置
- 农历与阳历相互转换
- 天干地支（GanZhi）数据模型
- 大运起运时间计算
- 灵活的地理位置和时区配置

## 待完善功能

目前该项目待后续完善功能，如纳音神煞等功能。

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  bazi_core: ^0.1.1
  sxwnl_spa_dart: ^0.9.6
```

## 快速开始

### 1. 从阳历时间创建八字

```dart
import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  // 创建阳历时间
  final solarTime = AstroDateTime(2026, 2, 18, 12, 0, 0);
  
  // 创建八字盘
  final chart = BaziChart.createBySolarDate(clockTime: solarTime);
  
  // 输出八字
  print('八字: ${chart.bazi}');
  // 输出农历日期
  print('农历: ${chart.lunarDate}');
}
```

### 2. 从农历时间创建八字

```dart
import 'package:bazi_core/bazi_core.dart';

void main() {
  final chart = BaziChart.createByLunarDate(
    year: 2025,
    monthName: "正",
    day: 1,
    hour: 12,
    minute: 0,
  );
  
  print('八字: ${chart.bazi}');
  print('农历: ${chart.lunarDate}');
}
```

### 3. 配置真太阳时和早晚子时

```dart
import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final time = AstroDateTime(2026, 2, 18, 23, 30, 0);
  
  final chart = BaziChart.createBySolarDate(
    clockTime: time,
    location: const Location(116.4, 39.9), // 北京经纬度
    timeZone: 8.0,
    splitByRatHour: true, // 区分早晚子时
    useTrueSolarTime: true, // 使用真太阳时
  );
  
  print('八字: ${chart.bazi}');
}
```

### 4. 获取空亡地支

获取该干支所在旬的空亡地支列表。
**注意**：返回列表的顺序为 **同性在前，异性在后**（即与天干阴阳相同的地支排在第一位，不同的排在第二位）。

```dart
import 'package:bazi_core/bazi_core.dart';

void main() {
  // 创建一个干支（例如：甲子，甲为阳干）
  final gz = GanZhi(TianGan.jia, DiZhi.zi);
  
  // 获取该干支所在旬的空亡地支
  // 甲子旬空亡为 戌(阳)、亥(阴)
  final kongWang = gz.getKongWang();
  
  // 输出结果：[DiZhi.xu, DiZhi.hai]
  // 戌(阳)与甲(阳)同性，故在前；亥(阴)与甲(阳)异性，故在后。
  print('甲子旬空亡: ${kongWang.map((e) => e.label).toList()}'); // [戌, 亥]
}
```

## API 文档

### BaziChart

八字盘主类，包含八字、时间信息和农历日期。

#### 构造方法

**`BaziChart.createBySolarDate`**

通过阳历时间创建八字盘。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `clockTime` | `AstroDateTime` | 是 | - | 阳历时间 |
| `location` | `Location` | 否 | `defaultLoc` | 地理位置（经纬度） |
| `timeZone` | `double` | 否 | `8.0` | 时区 |
| `splitByRatHour` | `bool` | 否 | `false` | 是否区分早晚子时 |
| `useTrueSolarTime` | `bool` | 否 | `true` | 是否使用真太阳时 |

**`BaziChart.createByLunarDate`**

通过农历时间创建八字盘。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `year` | `int` | 是 | - | 农历年份 |
| `monthName` | `String` | 是 | - | 农历月份名称（如"正"、"二"、"闰三"） |
| `day` | `int` | 是 | - | 农历日期 |
| `hour` | `int` | 是 | - | 小时 |
| `minute` | `int` | 是 | - | 分钟 |
| `second` | `int` | 否 | `0` | 秒 |
| `isleap` | `bool?` | 否 | `null` | 是否闰月 |
| `location` | `Location` | 否 | `defaultLoc` | 地理位置 |
| `timeZone` | `double` | 否 | `8.0` | 时区 |
| `splitByRatHour` | `bool` | 否 | `false` | 是否区分早晚子时 |
| `useTrueSolarTime` | `bool` | 否 | `true` | 是否使用真太阳时 |

#### 属性

- `time`: `TimePack` - 时间封装包
- `bazi`: `BaZi` - 八字数据
- `lunarDate`: `LunarDate` - 农历日期

### BaZi

八字数据模型，包含年、月、日、时四柱。

| 属性 | 类型 | 说明 |
|------|------|------|
| `year` | `GanZhi` | 年柱 |
| `month` | `GanZhi` | 月柱 |
| `day` | `GanZhi` | 日柱 |
| `time` | `GanZhi` | 时柱 |

### GanZhi

干支组合模型。

| 属性 | 类型 | 说明 |
|------|------|------|
| `gan` | `TianGan` | 天干 |
| `zhi` | `DiZhi` | 地支 |

### TianGan（天干枚举）

- `jia` - 甲
- `yi` - 乙
- `bing` - 丙
- `ding` - 丁
- `wu` - 戊
- `ji` - 己
- `geng` - 庚
- `xin` - 辛
- `ren` - 壬
- `gui` - 癸

### DiZhi（地支枚举）

- `zi` - 子
- `chou` - 丑
- `yin` - 寅
- `mao` - 卯
- `chen` - 辰
- `si` - 巳
- `wu` - 午
- `wei` - 未
- `shen` - 申
- `you` - 酉
- `xu` - 戌
- `hai` - 亥

### LunarDate

农历日期模型。

#### 构造方法

**`LunarDate.fromString`**

从农历字符串创建。

**`LunarDate.fromSolar`**

从阳历时间转换。

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `lunarYear` | `int` | 农历年份 |
| `month` | `int` | 农历月份 |
| `day` | `int` | 农历日期 |
| `isLeap` | `bool` | 是否闰月 |
| `monthNameStr` | `String` | 月份名称字符串 |
| `toSolar` | `AstroDateTime` | 转换为阳历时间 |

### TimePack

时间封装包，包含多种时间信息。

| 属性 | 类型 | 说明 |
|------|------|------|
| `clockTime` | `AstroDateTime` | 钟表时间 |
| `solarTime` | `SolarTimeResult` | 真太阳时结果 |
| `virtualTime` | `AstroDateTime` | 排盘基准时间 |
| `utcTime` | `AstroDateTime` | UTC 时间 |
| `timezone` | `double` | 时区 |
| `location` | `Location` | 地理位置 |
| `splitRatHour` | `bool` | 是否区分早晚子时 |

### Fortune

大运信息类，包含起运时间和每步大运信息。

#### 构造方法

**`Fortune.createByBaziChart`**

通过八字盘创建大运信息。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `bz` | `BaziChart` | 是 | - | 八字盘 |
| `daYunAlgorithm` | `DaYunAlgorithm` | 否 | `DaYunAlgorithm.precise120` | 大运算法 |

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `birthday` | `AstroDateTime` | 出生时间 |
| `qiYunTime` | `AstroDateTime` | 起运时间 |
| `qiYunDt` | `QiYunDt` | 起运详情（年、月、日、时、分、秒） |
| `startAge` | `double` | 起运年龄 |
| `direction` | `int` | 大运方向（1=顺行，-1=逆行） |
| `daYunBase` | `GanZhi` | 大运起始干支 |
| `xiaoYunBase` | `GanZhi` | 小运起始干支 |

#### 方法

- `getDecadeByIndex(int index)` - 获取第 index 步大运
- `getXiaoYunByAge(int age)` - 获取指定年龄的小运干支

### Decade

单步大运信息。

| 属性 | 类型 | 说明 |
|------|------|------|
| `index` | `int` | 第几步大运 |
| `startTime` | `AstroDateTime` | 大运开始时间 |
| `endTime` | `AstroDateTime` | 大运结束时间 |
| `startAge` | `int` | 起步虚岁 |
| `endAge` | `int` | 结束虚岁 |
| `ganZhi` | `GanZhi` | 大运干支 |

### Gender（性别枚举）

- `male` - 男性
- `female` - 女性

### DaYunAlgorithm（大运算法枚举）

- `precise120` - 精确120算法（默认）

## 示例

完整示例代码请参考 `test/bazi_core_test.dart`。

## 依赖

- `sxwnl_spa_dart: ^0.9.6` - 天文算法库

## 许可证

本项目采用 MIT 许可证。
