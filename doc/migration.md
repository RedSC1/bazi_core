# 0.7 纯 Dart 重写

新实现以 `bazi-lite`（`js-ephemeris-lite` 仓库的 `packages/bazi`）为基准，
底层改为 `ephemeris_lite`。旧实现保留在 `1ec0b5a` 及此前的 Git 历史，不在新运行库中混用。

## API 对应

| 旧 API | 新 API |
| --- | --- |
| `createBySolarDate` | `BaziChart.fromZonedTime` |
| `AstroDateTime`／`TimePack` | `ZonedTime`、`JulianTime`、独立 `CalendarDate` 计算钟表 |
| `BaZi`／`GanZhi` | `FourPillars`／经过校验的 packed `int` |
| `Fortune.createByBaziChart` | `chart.getQiYun()`、`chart.getDaYunTable()` |
| 自定义神煞类 | 默认 66 种稳定 ID、`collectTargetShenSha`；自定义规则改用不可变 `BaziShenShaCatalog` 用户模块 |
| `chart.taiXi` 等 | `chart.extraPillars.taiXi` 等 |
| `noSplit`／`todayGan`／`tomorrowGan` | `nextDay`／`currentDay`／`currentDayTomorrowStem` |
| 旧反查类 | `searchBaziDates`、`searchBaziTimesForDate`、`reverseLookupBazi` |

这是 API 重写，不承诺旧源码直接编译。旧表格展示类、全局可变规则列表和仅用于打印调试的
演示脚本不作为兼容层保留。需要农历信息时，直接调用独立 `ephemeris_lite`，
不在八字图表上隐含另一套历法状态。

## 测试迁移依据

- `primitives-cpp.json`：3,848 组有限域穷举，覆盖十神、藏干、空亡、长生、关系、流月/流时、司令。
- `charts-cpp.json`：1,024 张种子盘，覆盖三种性别设置、四柱神煞、附加柱、整盘关系汇总。
- `fortune-cpp.json`：144 组，覆盖三种起运 × 三种大运边界。
- `js-parity.json`：90 张跨年代/钟表/子时盘、56,160 次任意目标神煞对拍。
- 旧 Dart 的胎息、三种子时、13:00 整点、地转/天转/拱禄/拱贵案例已改写为新 API。
- JS 与旧 Dart 的正常日期、跨年子月、立春、历史交节、子时反查案例已迁入。
- `tool/web_smoke.dart` 检查 dart2js 的 66 位位集、排盘、运表、JSON 和反查。

C++ 起运夹具使用较早的未来 ΔT 模型，2027 年之后沿用 JS 测试已注明的较宽时刻容差；
JS 直接对拍另用更严格的容差检查语言移植误差，不能将前者当作当前天文误差声明。

旧神煞负例曾使用不存在的“甲丑”，现在以合法的“乙丑”验证不同日时干不触发拱禄，
同时单独断言不存在的干支组合被拒绝。

重新生成 JS 夹具（先构建 JS 八字包）：

```sh
node tool/generate_js_oracle.mjs ../taiyin-lite
```

`1.0.0-beta.1` 已改用公开发布的 `ephemeris_lite`。从 `0.6.x` 升级时需要迁移调用点，
不应依赖旧版的全局状态或展示层对象。

完整公开接口对应见 [api-map.md](api-map.md)；新用户模块扩展见 [shen-sha-catalog.md](shen-sha-catalog.md)。
