# 神煞用户模块

扩展接口与 C++ 的 `BaziShenShaCatalog` 对齐：**定义、选择、计算分开**。
默认 66 种规则始终存在，不能覆盖或删除；换流派时增加自己的规则，再停用不采用的默认判定。
原有固定神煞位集接口不受影响。

## 使用方式

```dart
final catalog = BaziShenShaCatalog().addModule(
  BaziShenShaModule('my-school', [
    BaziShenShaRule('day-marker', '日柱示例',
      (input) => input.targetKind == ShenShaTarget.day),
  ]),
);
final context = catalog.createContext(
  BaziShenShaSelection(disabledIds: ['builtin:0']),
);
final matches = context.evaluate(chart, chart.pillars.day, ShenShaTarget.day,
  gender: chart.options.gender);
final removed = catalog.removeModule('my-school');
// removed 不含该模块；catalog 与已有 context 不变。
```

完整可编译示例：`example/shen_sha_catalog.dart`。

| 操作 | 语义 |
| --- | --- |
| `BaziShenShaModule(label, rules)` | 不可变用户规则模块，不允许空模块 |
| `catalog.addModule(module)` | 返回新目录，重复模块名报错 |
| `catalog.removeModule(label)` | 返回新目录，移除该模块的全部规则；未知模块报错 |
| `catalog.createContext(selection)` | 保存规则和停用选择的快照，不绑定某一张盘 |
| `context.evaluate(chart, target, targetKind, gender: ...)` | 用指定盘计算目标神煞，返回只读匹配列表 |

模块名和局部规则 ID 必须非空，不能包含冒号或空白。`builtin`、`option1` 是保留模块名。
完整自定义 ID 自动组成 `模块名:规则ID`；默认 ID 为 `builtin:0` 至 `builtin:65`。
模块内重复规则 ID、重复模块名、未知或重复的 `disabledIds` 均报错。
空选择启用全部规则；要恢复默认配置，创建新的空目录即可。

## 回调与结果

回调收到 `input.chart`、`target`、`targetKind`、`gender`。
`chart` 是完整**规则层盘数据副本**：四柱、附加柱、十神、藏干、长生、纳音等，
对应 C++ 的规则盘；不包含出生时刻、星历实例或历法上下文的所有权。

回调是同步纯函数，异常向外传播，不返回部分结果；停用的回调不会执行。
快照仅隔离规则集合和选择，无法深拷贝闭包捕获的外部可变状态。

匹配项为 `{ id, name, builtinId }`：

- 内置：`name` 为空，`builtinId` 为 0–65，上层按编号选择本地化名称。
- 自定义：`name` 为用户名称，`builtinId` 为 `-1`，不占用原有位集位置。
- 顺序：内置 ID 递增，然后按模块、规则添加顺序。

JS 未指定性别用 `undefined`，Dart 用 `null`，对应 C++ 的 `-1`。
不自动从盘推断性别。匹配结果可以 JSON 序列化，回调不能；目录不隐式写入图表 JSON。

## 从未发布的注册表草案迁移

`ShenShaRegistry`、`replace/remove/clear/reset`、`bind(chart)` 已移除，不保留别名。
新增改用 `addModule`；逐条禁用改用 `disabledIds`；整流派删除改用 `removeModule`。
替代内置判定必须使用自己的模块 ID，不能复用或重写 `builtin:N`。
