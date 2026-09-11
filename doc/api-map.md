# JS → Dart 公开 API 对应

以 `bazi-lite/src/index.ts` 导出项为范围。函数功能对应；语言级接口不要求参数外形完全一致。

| JS 导出 | Dart 对应 |
| --- | --- |
| `BaziChart.fromInstant` / `calculateBazi` | 同名，支持数值 UT1 JD 或 `JulianTime` |
| `BaziChart.fromZonedTime` / `baziForZonedTime` | 同名，`options:` 命名参数 |
| `analyzePillars` | 同名，`earthPalaceMode:` 命名参数 |
| `BaziOptions` / `resolveBaziOptions` | 同名；构造器命名参数或 `BaziOptions.fromJson` |
| `BaziOptions.with` | `copyWith`；可用 `clearGender` / `clearLongitude` 显式清空可选字段 |
| `toFourPillarsOptions` | `calendarOptions`、`ratHourMode`、`pillarHistoricalMode` 直接传给底层命名参数 |
| `toQiYunOptions` / `toDaYunOptions` | `calendarOptions` / `qiYunTimeModel` / `daYunBoundaryModel` / `daYunCount` 直接传对应命名参数 |
| `toJSON` / `BaziChartJSON` | `toJson()` / `Map<String, Object?>`，可用 `jsonEncode(chart)` |
| `packPillar` / `unpackPillar` / `DecodedPillar` | 同名 |
| `pillarStem` / `pillarBranch` / `pillarIndex` / `pillarName` | 同名 |
| `getKongWang` / `getTenGod` / `getHiddenStems` / `getLifeStage` | 同名 |
| `calculateStemRelation` / `calculateBranchRelation` / `calculateBranchTripleRelation` | 同名，返回 `RelationFlags` |
| `calculateExtraPillars` | 同名，返回 `ExtraPillars` |
| `collectChartRelations` | 同名，`pillarMask:` / `relationMask:` 命名参数 |
| `calculateFlowYear/Month/Day/Hour` / `calculateLuckDirection` | 同名 |
| `calculateXiaoYun` / `generateXiaoYun` / `generateDaYunPillars` | 同名 |
| `calculateQiYun` / `generateDaYun` | 同名，模型/数量使用命名参数 |
| `getRenyuanSilingSegments` / `selectRenyuanSiling` | 同名 |
| `collectTargetShenSha` / `collectNatalShenSha` | 同名，规则分析盘 + 命名 `gender:` |
| `hasShenSha` / `shenShaIds` / `shenShaNames` / `shenShaWords` | 同名；后者返回 `(BigInt, BigInt)` |
| `searchBaziDates` / `BaziDateSearchQuery` | 同名 |
| `searchBaziTimesForDate({dateCandidate, hour})` | `searchBaziTimesForDate(candidate, hour: ...)` |
| `reverseLookupBazi` / `BaziFullSearchQuery` | 函数同名，查询字段改为命名参数 |
| 图表列、起运结果、大小运、人元司令和反查结果类型 | 对应同名 Dart 类；`BaziColumnKey` 的四个 key 仍为字符串 |
| `BaziShenShaModule` / `BaziShenShaCatalog` / `BaziShenShaContext` | 同名；回调为 `bool Function(BaziShenShaInput)` |

## 常量与类型

| JS | Dart |
| --- | --- |
| `INVALID_ID` / `RELATION_KIND_MASK_ALL` | `invalidId` / `relationKindMaskAll` |
| `WUXING` / `WUXING_NAMES` | `Wuxing` 枚举 / `wuxingNames` |
| `TEN_GOD` / `TEN_GOD_NAMES` | `TenGodId` 静态常量 / `tenGodNames` |
| `LIFE_STAGE` / `LIFE_STAGE_NAMES` | `LifeStageId` 静态常量 / `lifeStageNames` |
| `PILLAR_SLOT` / `PILLAR_MASK` | `PillarSlot` / `PillarMask` 静态常量 |
| `SHEN_SHA` / `SHEN_SHA_NAMES` / `SHEN_SHA_TARGET` | `ShenShaId` / `shenShaNameTable` / `ShenShaTarget` |
| `STEM_RELATION_FLAG` / `BRANCH_RELATION_FLAG` / `BRANCH_TRIPLE_RELATION_FLAG` | 对应 PascalCase 类的 lowerCamelCase 常量 |
| `RELATION_KIND` | `RelationKind` 枚举，`.index` 保持 JS 编号 |
| 性别、钟表、长生土宫、起运/大运、司令选项 | 对应 Dart 枚举，见公开构造器 |
| `BRANCH_COMBINATION_PARTNER` / `BRANCH_TRIPLE_*` / `TRIPLE_ELEMENT` | 同名 lowerCamelCase 常量列表 |
| `BAZI_LITE_INFO` / `BAZI_RULE_INFO` / `SHEN_SHA_INFO` | `baziLiteInfo` / `baziRuleInfo` / `shenShaInfo` |
| `PackedPillar` / `ShenShaBitset` | 同名 typedef，分别为 `int` / `BigInt` |
| TS 的 ID 数值联合类型和参数 options interface | Dart 的 `int`、枚举、命名参数或已有设置类，不增加空包装类 |

Dart 的历法设置集中在 `CalendarOptions`，而 JS 在 `BaziOptionsInput` 中使用扁平字段。
JSON 仍接受/输出扁平字段。Dart 额外保留底层 `eventAccuracy`；读取没有该字段的 JS 选项时默认 `mid`。

本表不承诺旧 Dart 0.6 展示层类的兼容，详见 `migration.md`。

`BaziShenShaSelection` 在 JS 为 options interface，在 Dart 为不可变类；匹配项两边均为 `BaziShenShaMatch`。
