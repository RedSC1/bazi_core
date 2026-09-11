part of '../bazi_core.dart';

enum RelationKind {
  stemCombination,
  stemClash,
  stemRestraint,
  branchCombination,
  branchClash,
  branchHarm,
  branchDestruction,
  branchTriplePunishment,
  branchPunishment,
  branchSelfPunishment,
  branchTripleCombination,
  branchTripleDirection,
  branchHalfCombination,
  branchArchingCombination,
  branchHiddenCombination,
  branchSeverance,
}

class PillarMask {
  static const year = 1,
      month = 2,
      day = 4,
      hour = 8,
      mingGong = 16,
      shenGong = 32,
      taiYuan = 64,
      taiXi = 128,
      primary = 15,
      extra = 240,
      all = 255;
}

class BaziRelation {
  final RelationKind kind;
  final int pillarMask;
  final int? combinedElement;
  const BaziRelation(this.kind, this.pillarMask, this.combinedElement);
  Map<String, Object?> toJson() => {
    'kind': kind.index,
    'pillarMask': pillarMask,
    'combinedElement': combinedElement,
  };
}

class _Node {
  final int value, sourceId;
  const _Node(this.value, this.sourceId);
  int get flag => 1 << sourceId;
}

class _Pending {
  final int kind;
  final int? element;
  int pillars, values;
  _Pending(this.kind, this.element, this.pillars, this.values);
}

/// Stable JS relation IDs, including suppression of pairs covered by triples.
List<BaziRelation> collectChartRelations(
  BaziPillarAnalysis chart, {
  int pillarMask = PillarMask.primary,
  int relationMask = 0xffff,
}) {
  if (pillarMask <= 0 || pillarMask > 255) {
    throw RangeError('Unknown pillarMask');
  }
  if (relationMask < 0 || relationMask > 0xffff) {
    throw RangeError('Unknown relationMask');
  }
  final values = [
    ...chart.pillars.toJson().values,
    ...chart.extraPillars.toJson().values,
  ];
  List<_Node> nodes(bool stems) => [
    for (var i = 0; i < 8; i++)
      if ((pillarMask & (1 << i)) != 0)
        _Node(stems ? ganzhiStem(values[i]) : ganzhiBranch(values[i]), i),
  ];
  final pending = <_Pending>[];
  bool enabled(int kind) => (relationMask & (1 << kind)) != 0;
  void add(int kind, List<_Node> ns, int? element) {
    if (!enabled(kind)) return;
    final pm = ns.fold(0, (a, n) => a | n.flag),
        vm = ns.fold(0, (a, n) => a | (1 << n.value));
    for (final p in pending) {
      if (p.kind == kind && p.element == element && (p.values & vm) != 0) {
        p.pillars |= pm;
        p.values |= vm;
        return;
      }
    }
    pending.add(_Pending(kind, element, pm, vm));
  }

  final stems = nodes(true), branches = nodes(false);
  for (var kind = 0; kind < 3; kind++) {
    final count = const [5, 4, 10][kind];
    for (var first = 0; first < count; first++) {
      final second = kind == 0
          ? first + 5
          : kind == 1
          ? first + 6
          : (first + 4) % 10;
      final ns = stems
          .where((n) => n.value == first || n.value == second)
          .toList();
      if (ns.any((n) => n.value == first) && ns.any((n) => n.value == second)) {
        add(
          kind,
          ns,
          kind == 0
              ? calculateStemRelation(first, second).combinedElement
              : null,
        );
      }
    }
  }
  int pairKey(_Node a, _Node b) => a.sourceId < b.sourceId
      ? a.sourceId * 8 + b.sourceId
      : b.sourceId * 8 + a.sourceId;
  final suppressed = <int>{};
  for (var i = 0; i < branches.length; i++) {
    for (var j = i + 1; j < branches.length; j++) {
      for (var k = j + 1; k < branches.length; k++) {
        final trio = [branches[i], branches[j], branches[k]];
        for (final (groups, kind) in [
          (branchTripleDirection, 11),
          (branchTripleCombination, 10),
          (branchTriplePunishment, 7),
        ]) {
          for (var g = 0; g < groups.length; g++) {
            if (!_triple(
              trio[0].value,
              trio[1].value,
              trio[2].value,
              groups[g],
            )) {
              continue;
            }
            add(kind, trio, kind == 7 ? null : tripleElement[g]);
            suppressed.addAll([
              pairKey(trio[0], trio[1]),
              pairKey(trio[0], trio[2]),
              pairKey(trio[1], trio[2]),
            ]);
          }
        }
      }
    }
  }
  for (var i = 0; i < branches.length; i++) {
    for (var j = i + 1; j < branches.length; j++) {
      final a = branches[i],
          b = branches[j],
          pair = [a, b],
          suppress = suppressed.contains(pairKey(a, b));
      if (!suppress && a.value != b.value) {
        for (var g = 0; g < 4; g++) {
          final group = branchTripleCombination[g];
          if (group.contains(a.value) && group.contains(b.value)) {
            add(
              a.value == group[1] || b.value == group[1] ? 12 : 13,
              pair,
              tripleElement[g],
            );
          }
        }
      }
      final r = calculateBranchRelation(a.value, b.value);
      for (final (flag, kind) in [
        (16, 8),
        (1, 3),
        (2, 4),
        (4, 5),
        (8, 6),
        (64, 14),
        (128, 15),
      ]) {
        if ((r.flags & flag) != 0 && !(kind == 8 && suppress)) {
          add(kind, pair, kind == 3 ? r.combinedElement : null);
        }
      }
    }
  }
  for (final value in [4, 6, 9, 11]) {
    final ns = branches.where((n) => n.value == value).toList();
    if (ns.length >= 2) add(9, ns, null);
  }
  return List.unmodifiable(
    pending.map(
      (p) => BaziRelation(RelationKind.values[p.kind], p.pillars, p.element),
    ),
  );
}
