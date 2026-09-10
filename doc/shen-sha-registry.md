# 实例级神煞注册表

`ShenShaRegistry` 支持新增、替换、删除和恢复默认规则。每个实例独立，不修改全局状态。
默认包含原有 66 种神煞；仅需要自定义规则时使用 `ShenShaRegistry(includeBuiltins: false)`。

```dart
final registry = ShenShaRegistry();
registry.register(ShenShaRule(
  id: 'example:day-marker',
  name: '日柱示例',
  test: (context) => context.targetKind == ShenShaTarget.day,
));
final bound = registry.bind(chart, gender: chart.options.gender);
final natal = bound.natal();
final mingGong = bound.forTarget(chart.extraPillars.mingGong, ShenShaTarget.mingGong);
```

可编译的完整示例见 `example/shen_sha_registry.dart`。

| 方法 | 行为 |
| --- | --- |
| `register(rule)` | 新增，重复 ID 报错；返回注册表本身 |
| `replace(rule)` | 替换已存在的规则，保持顺序；不存在时报错 |
| `remove(id)` | 删除规则，返回是否存在 |
| `clear()` | 清空全部规则 |
| `reset()` | 恢复默认 66 种，移除全部自定义规则 |
| `snapshot()` | 保存当前规则集合，返回不可变 `ShenShaRuleSet` |
| `bind(chart, gender: ...)` | 绑定规则集合快照、四柱副本和性别 |

内置规则 ID 是 `builtin:0` 至 `builtin:65`，对应 `ShenShaId` 中的稳定编号。
`builtin:` 前缀保留，不能通过 `register` 新增；可以通过 `replace` 替换已有内置规则，
或通过 `remove` 禁用。自定义 ID 建议加项目命名空间，例如 `my-app:rule-name`。

回调收到 `{ pillars, target, targetKind, gender }`；返回值必须是同步 `bool`。
异常会向调用者传播，不会静默跳过规则。未传 `gender` 时为 `null`，
与原 `collectTargetShenSha` 一致；注册表不会自动从图表推断性别。

## 隔离与序列化

- 注册表后续修改不改变已绑定的规则集合或盘的四柱副本。
- 回调必须是纯函数。函数闭包引用的外部变量无法深拷贝；不要让判定依赖随后变化的外部状态。
- 匹配结果为只读 `{ id, name, builtinId? }[]`。只有未修改的内置规则包含 `builtinId`。
- 替换内置规则仍保留其字符串 ID，但不再标记为默认内置判定。
- `getShenSha()` 和原位集接口仍使用固定的默认 66 种规则，不会受注册表影响。
- 注册表不写进 `BaziOptions` 或 `chart.toJson()`。需要导出扩展结果时，显式保存
  `bound.natal()` 或 `forTarget()` 的结果；这些结果可 JSON 序列化，回调本身不可序列化。

这提供旧可变注册表的扩展能力，但不恢复跨盘共享的全局可变列表。
