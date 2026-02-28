import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'enums.dart';
import 'bazi_table.dart';

/// 参与刑冲合害的干支节点 (包装了位置信息)
class InteractionNode<T> {
  /// 柱的位置来源 (如：year, decade)
  final PillarType pillar;
  /// 干或支的值
  final T value;

  InteractionNode(this.pillar, this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionNode &&
          runtimeType == other.runtimeType &&
          pillar == other.pillar &&
          value == other.value;

  @override
  int get hashCode => pillar.hashCode ^ value.hashCode;

  @override
  String toString() => '${pillar.name}: $value';
}

/// 刑冲合害结果模型 (合并模式)
class InteractionResult {
  /// 刑冲合害类型
  final BaziInteraction type;
  /// 参与感应的所有节点列表
  final List<InteractionNode> nodes;
  /// 化合后的五行结果 (仅限合局，其余为 null)
  final WuXing? combinedWuXing;

  InteractionResult({
    required this.type,
    required this.nodes,
    this.combinedWuXing,
  });
}

/// 内部使用的带 ID 节点
class _InternalNode {
  final int id;
  final InteractionNode<DiZhi> original;
  _InternalNode(this.id, this.original);
  DiZhi get value => original.value;
}

class BaziInteractionCalculator {
  /// 计算天干刑冲合害 (合并模式)
  static List<InteractionResult> calculateStemInteractions(
    List<InteractionNode<TianGan>> stems, {
    Set<BaziInteraction>? enabledTypes,
  }) {
    List<InteractionResult> results = [];

    // 1. 天干五合
    for (int i = 0; i < 5; i++) {
      final t1 = TianGan.values[i];
      final t2 = TianGan.values[i + 5];
      final matched = stems.where((s) => s.value == t1 || s.value == t2).toList();
      final types = matched.map((e) => e.value.index % 10).toSet();
      if (types.length == 2) {
        results.add(InteractionResult(
          type: BaziInteraction.stemCombination,
          nodes: matched,
          combinedWuXing: BaziTable.getStemCombinationResult(t1, t2),
        ));
      }
    }

    // 2. 天干相冲
    final clashPairs = [[0, 6], [1, 7], [2, 8], [3, 9]];
    for (var pair in clashPairs) {
      final matched = stems.where((s) => pair.contains(s.value.index % 10)).toList();
      final types = matched.map((e) => e.value.index % 10).toSet();
      if (types.length == 2) {
        results.add(InteractionResult(type: BaziInteraction.stemClash, nodes: matched));
      }
    }

    // 3. 天干相克 (同性)
    for (int i = 0; i < 10; i++) {
      final restrainerIdx = i;
      final restrainedIdx = (i + 4) % 10;
      final matched = stems.where((s) {
        int idx = s.value.index % 10;
        return idx == restrainerIdx || idx == restrainedIdx;
      }).toList();
      final types = matched.map((e) => e.value.index % 10).toSet();
      if (types.length == 2) {
        results.add(InteractionResult(type: BaziInteraction.stemRestraint, nodes: matched));
      }
    }

    // 过滤与去重
    var finalResults = _mergeResults(results);
    if (enabledTypes != null) {
      finalResults.retainWhere((res) => enabledTypes.contains(res.type));
    }
    return finalResults;
  }

  /// 计算地支刑冲合害 (合并模式)
  static List<InteractionResult> calculateBranchInteractions(
    List<InteractionNode<DiZhi>> branches, {
    Set<BaziInteraction>? enabledTypes,
  }) {
    List<InteractionResult> results = [];
    final nodes = List.generate(branches.length, (i) => _InternalNode(i, branches[i]));
    final Set<String> suppressedPairs = {};

    // ===========================================================================
    // A. 扫描三元素组合 (C(n, 3))：优先匹配大局，并填充抑制名单
    // ===========================================================================
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        for (int k = j + 1; k < nodes.length; k++) {
          final trio = [nodes[i], nodes[j], nodes[k]];
          final values = trio.map((e) => e.value.index % 12).toSet();

          // 1. 三会局
          for (int g = 0; g < BaziTable.branchTripleDirectionGroups.length; g++) {
            final group = BaziTable.branchTripleDirectionGroups[g];
            if (values.containsAll(group)) {
              results.add(InteractionResult(
                type: BaziInteraction.branchTripleDirection,
                nodes: trio.map((e) => e.original).toList(),
                combinedWuXing: BaziTable.getTripleDirectionWuXing(g),
              ));
              // 三会通常抑制内部的各种感应
              _suppressAllPairs(suppressedPairs, trio);
            }
          }

          // 2. 三合局
          for (int g = 0; g < BaziTable.branchTripleCombinationGroups.length; g++) {
            final group = BaziTable.branchTripleCombinationGroups[g];
            if (values.containsAll(group)) {
              results.add(InteractionResult(
                type: BaziInteraction.branchTripleCombination,
                nodes: trio.map((e) => e.original).toList(),
                combinedWuXing: BaziTable.getTripleCombinationWuXing(g),
              ));
              _suppressAllPairs(suppressedPairs, trio);
            }
          }

          // 3. 三刑全
          for (var group in BaziTable.branchTriplePunishmentGroups) {
            if (values.containsAll(group)) {
              results.add(InteractionResult(
                type: BaziInteraction.branchTriplePunishment,
                nodes: trio.map((e) => e.original).toList(),
              ));
              // 关键修复：三刑全也需要抑制两两相刑
              _suppressAllPairs(suppressedPairs, trio);
            }
          }
        }
      }
    }

    // ===========================================================================
    // B. 扫描两两关系：应用抑制逻辑并合并
    // ===========================================================================
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];
        final pairKey = _getPairKey(a.id, b.id);
        final isSuppressed = suppressedPairs.contains(pairKey);

        // 1. 半合/拱合
        if (!isSuppressed) {
          for (int g = 0; g < BaziTable.branchTripleCombinationGroups.length; g++) {
            final group = BaziTable.branchTripleCombinationGroups[g];
            final vA = a.value.index % 12;
            final vB = b.value.index % 12;
            if (group.contains(vA) && group.contains(vB) && vA != vB) {
              bool hasMiddle = vA == group[1] || vB == group[1];
              results.add(InteractionResult(
                type: hasMiddle ? BaziInteraction.branchHalfCombination : BaziInteraction.branchArchingCombination,
                nodes: [a.original, b.original],
                combinedWuXing: BaziTable.getTripleCombinationWuXing(g),
              ));
            }
          }
        }

        // 2. 两两相刑
        if (!isSuppressed && BaziTable.isBranchPunishment(a.value, b.value)) {
          results.add(InteractionResult(type: BaziInteraction.branchPunishment, nodes: [a.original, b.original]));
        }

        // 3. 六合、六冲等基础关系 (不被三元素抑制，但需要合并同类项)
        if (BaziTable.isBranchCombination(a.value, b.value)) {
          results.add(InteractionResult(
            type: BaziInteraction.branchCombination,
            nodes: [a.original, b.original],
            combinedWuXing: BaziTable.getBranchCombinationResult(a.value, b.value),
          ));
        }
        if (BaziTable.isBranchClash(a.value, b.value)) {
          results.add(InteractionResult(type: BaziInteraction.branchClash, nodes: [a.original, b.original]));
        }
        if (BaziTable.isBranchHarm(a.value, b.value)) {
          results.add(InteractionResult(type: BaziInteraction.branchHarm, nodes: [a.original, b.original]));
        }
        if (BaziTable.isBranchDestruction(a.value, b.value)) {
          results.add(InteractionResult(type: BaziInteraction.branchDestruction, nodes: [a.original, b.original]));
        }
        if (BaziTable.isBranchHiddenCombination(a.value, b.value)) {
          results.add(InteractionResult(type: BaziInteraction.branchHiddenCombination, nodes: [a.original, b.original]));
        }
        if (BaziTable.isBranchSeverance(a.value, b.value)) {
          results.add(InteractionResult(type: BaziInteraction.branchSeverance, nodes: [a.original, b.original]));
        }
      }
    }

    // C. 特殊处理：自刑 (辰午酉亥)
    final selfTypes = [4, 6, 9, 11];
    for (var idx in selfTypes) {
      final matched = branches.where((b) => b.value.index % 12 == idx).toList();
      if (matched.length >= 2) {
        results.add(InteractionResult(type: BaziInteraction.branchSelfPunishment, nodes: matched));
      }
    }

    var finalResults = _mergeResults(results);
    if (enabledTypes != null) {
      finalResults.retainWhere((res) => enabledTypes.contains(res.type));
    }
    return finalResults;
  }

  static String _getPairKey(int id1, int id2) => id1 < id2 ? '$id1-$id2' : '$id2-$id1';

  static void _suppressAllPairs(Set<String> set, List<_InternalNode> trio) {
    set.add(_getPairKey(trio[0].id, trio[1].id));
    set.add(_getPairKey(trio[0].id, trio[2].id));
    set.add(_getPairKey(trio[1].id, trio[2].id));
  }

  /// 合并相同类型且规则成员相同的感应
  static List<InteractionResult> _mergeResults(List<InteractionResult> raw) {
    if (raw.isEmpty) return [];
    List<InteractionResult> merged = [];
    for (var res in raw) {
      bool found = false;
      for (int i = 0; i < merged.length; i++) {
        var m = merged[i];
        if (m.type == res.type && m.combinedWuXing == res.combinedWuXing) {
          var mNames = m.nodes.map((n) => n.value.index).toSet();
          var resNames = res.nodes.map((n) => n.value.index).toSet();
          // 如果名字集有交集（即属于同一组感应，如都是 丑-未 相关的）
          if (mNames.intersection(resNames).isNotEmpty) {
            final combinedNodes = [...m.nodes, ...res.nodes].toSet().toList();
            merged[i] = InteractionResult(
              type: m.type,
              nodes: combinedNodes,
              combinedWuXing: m.combinedWuXing,
            );
            found = true;
            break;
          }
        }
      }
      if (!found) merged.add(res);
    }
    return merged;
  }
}
