# bazi_core

基于 `ephemeris_lite` 的纯 Dart 八字库，由本项目的 `bazi-lite` 移植。
支持四柱、十神、藏干、长生、纳音、神煞、刑冲合害、起运与运表，以及出生日期和时辰反查。

> **重大破坏性更新**：重写版 API 与旧版 `0.6.x` 不兼容，升级前请阅读[迁移说明](https://github.com/RedSC1/bazi_core/blob/main/doc/migration.md)。旧版实现和授权仍保留在 Git 历史中。
> 新版将天文与历法内核由 `sxwnl_spa_dart` 迁移至 `ephemeris_lite`。

旧版采用的 `sxwnl_spa_dart` 以既有算法移植与兼容为主要目标，不适合持续加入排盘专用的底层能力。重写版改用本项目维护的 `ephemeris_lite`，便于统一定制气朔精度、历史历法归日、太阳时和子时边界等需要天文内核配合的功能。

排盘所用民用日期范围跟随内核，为天文纪年 −6000～10000 年；年 `0` 表示公元前 1 年。该范围表示接口可计算的目标区间，不代表所有年代具有相同精度；历史历法和 ΔT 的限制以 `ephemeris_lite` 文档为准。

当前稳定版本：`1.0.0`。

## 安装

```yaml
dependencies:
  bazi_core: ^1.0.0
```

运行 `dart pub get`，Flutter 项目使用 `flutter pub get`。

检出仓库后可运行：

```sh
dart pub get
dart analyze
dart test
dart run example/bazi_core_example.dart
```

## 排盘

```dart
import 'package:bazi_core/bazi_core.dart';

final chart = BaziChart.fromZonedTime(
  ZonedTime(
    year: 2000, month: 1, day: 1, hour: 12,
    offsetMinutes: 480,
  ),
  options: BaziOptions(
    gender: Gender.male,
    ratHourMode: RatHourMode.nextDay,
  ),
);

final columns = chart.columns;
final qiYun = chart.getQiYun();
final decades = chart.getDaYunTable();
final shenSha = chart.getShenSha();
final relations = collectChartRelations(chart);
final json = chart.toJson();
```

不提供性别时仍可排盘，性别相关的神煞不启用；起运/大运方法会明确报错，
JSON 中的 `fortune` 为 `null`。

### 历法、精度与太阳时

```dart
final options = BaziOptions(
  calendarOptions: CalendarOptions(
    mode: CalendarMode.historical,
    eventAccuracy: Accuracy.mid,
    utcOffsetMinutes: 480,
  ),
  pillarHistoricalMode: PillarHistoricalMode.followCalendar,
  clockMode: BaziClockMode.trueSolar,
  longitudeDeg: 116.4074,
  gender: Gender.female,
);
```

- `calendarOptions.eventAccuracy` 控制定气定朔算法档位，默认 `mid`，可选 `fast`、`accurate`。
- `pillarHistoricalMode` 控制年、月柱是否采用历史节气日；与天文计算精度独立。
- `clockMode` 可选民用钟表时间、平太阳时、真太阳时。太阳时需要提供经度。
- `clockMode` 默认 `BaziClockMode.civil`；旧版 `TimePack`／`createBySolarDate` 默认启用真太阳时，迁移旧调用时应显式选择 `BaziClockMode.trueSolar` 并填写经度。
- `ZonedTime.offsetMinutes` 表示输入钟表的时区；`calendarOptions` 表示历法设置，两者独立。
- `fromInstant(jdUT1, virtualTime)` 接受物理时刻和已处理的计算钟表，不会再次转换太阳时。
- 年份采用天文编号，`0` 为公元前 1 年；使用 1582 年切换的儒略／格里高利混合历。

### 子时规则

| Dart | 行为 |
| --- | --- |
| `RatHourMode.nextDay` | 23:00 换日，时干跟随次日；即旧 `noSplit` |
| `RatHourMode.currentDay` | 00:00 换日，晚子时使用当日日干 |
| `RatHourMode.currentDayTomorrowStem` | 00:00 换日，晚子时时干借用次日日干 |

### 已知四柱的规则分析

```dart
final analysis = analyzePillars(FourPillars(
  year: makeGanzhi(2, 6), month: makeGanzhi(6, 2),
  day: makeGanzhi(4, 2), hour: makeGanzhi(3, 5),
));
final extras = analysis.extraPillars;
final flags = collectTargetShenSha(
  analysis, analysis.pillars.day, ShenShaTarget.day,
  gender: Gender.male,
);
final names = shenShaNames(flags);
final hasGuiRen = hasShenSha(flags, ShenShaId.tianYiGuiRen);
```

四柱用 `int` 保存：高四位为天干，低四位为地支。`makeGanzhi` 拒绝不存在的干支配对。
`analyzePillars` 不虚构生日或起运时刻；神煞位集使用 `BigInt`，包括超过 64 位的标识。

### 起运和运表

- `QiYunTimeModel`：传统历年/月日换算、儒略年换算、回归年换算。
- `DaYunBoundaryModel`：民用历年、儒略年、回归年边界。
- 起运节气间隔使用**天文交节时刻**，与历史年/月柱的节气日划分分别处理，保持 JS 行为。
- `generateDaYunPillars`、`generateXiaoYun` 是无需天文时刻的规则接口。
- `calculateFlowYear/Month/Day/Hour` 生成流运干支。
- `getRenyuanSilingSegments`、`selectRenyuanSiling` 提供两套人元司令表。

### 反查

```dart
final matches = reverseLookupBazi(
  year: chart.pillars.year,
  month: chart.pillars.month,
  day: chart.pillars.day,
  hour: chart.pillars.hour,
  startDate: const CalendarDate(year: 1990, month: 1, day: 1),
  endDate: const CalendarDate(year: 2010, month: 12, day: 31),
  options: chart.options,
);
```

也可分两步调用 `searchBaziDates(BaziDateSearchQuery(...))` 和
`searchBaziTimesForDate(candidate, hour: ...)`。日期范围包含首尾日；
时辰结果的 `startTime`／`endTime` 为包含端点的范围，搜索分辨率为一秒。
交节日保留交节前后分段，历史边界复用底层四柱的统一接口。

## 测试与迁移

见 [迁移说明](https://github.com/RedSC1/bazi_core/blob/main/doc/migration.md)。测试包括共享 C++ 夹具、JS 直接对拍、旧版回归案例，
以及 Dart 编译到 JavaScript 后的冒烟测试。

```sh
dart compile js tool/web_smoke.dart -o /tmp/bazi-web-smoke.js
node /tmp/bazi-web-smoke.js
```

规则属于传统民俗资料，结果不构成现实决策建议。

## 许可

新实现移植自本项目 MPL-2.0 的 `bazi-lite`，采用 MPL-2.0，见 [LICENSE](https://github.com/RedSC1/bazi_core/blob/main/LICENSE)。
旧版 MIT 实现的许可保留在其 Git 历史中；依赖来源见
[第三方说明](https://github.com/RedSC1/bazi_core/blob/main/THIRD_PARTY_NOTICES.zh-CN.md)。

## 扩展规则与完整接口表

[公开 API 对应表](https://github.com/RedSC1/bazi_core/blob/main/doc/api-map.md) 列出 JS 导出项的 Dart 对应。
[神煞用户模块](https://github.com/RedSC1/bazi_core/blob/main/doc/shen-sha-catalog.md) 使用不可变目录与选择快照，内置定义只能停用，不能覆盖或删除。
