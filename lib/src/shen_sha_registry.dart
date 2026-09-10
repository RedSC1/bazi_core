part of '../bazi_core.dart';

class ShenShaContext {
  final FourPillars pillars;
  final int target;
  final ShenShaTarget targetKind;
  final Gender? gender;
  const ShenShaContext({
    required this.pillars,
    required this.target,
    required this.targetKind,
    this.gender,
  });
}

/// Predicates must be pure: captured application state is not snapshotted.
class ShenShaRule {
  final String id, name;
  final bool Function(ShenShaContext) test;
  ShenShaRule({required this.id, required this.name, required this.test}) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('Rule id/name must be nonempty');
    }
  }
}

class ShenShaMatch {
  final String id, name;
  final int? builtinId;
  const ShenShaMatch(this.id, this.name, [this.builtinId]);
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'builtinId': ?builtinId,
  };
}

class _RuleEntry {
  final String id, name;
  final int? builtinId;
  final bool Function(ShenShaContext)? test;
  const _RuleEntry(this.id, this.name, this.builtinId, this.test);
  factory _RuleEntry.custom(ShenShaRule rule) =>
      _RuleEntry(rule.id, rule.name, null, rule.test);
}

/// Mutable instance-local builder; binding copies its current rule collection.
class ShenShaRegistry {
  final Map<String, _RuleEntry> _rules = {};
  ShenShaRegistry({bool includeBuiltins = true}) {
    if (includeBuiltins) reset();
  }
  int get size => _rules.length;
  ShenShaRegistry register(ShenShaRule rule) {
    if (rule.id.startsWith('builtin:')) {
      throw ArgumentError(
        'builtin: is reserved; use replace for existing built-ins',
      );
    }
    if (_rules.containsKey(rule.id)) {
      throw ArgumentError('Duplicate rule: ${rule.id}');
    }
    _rules[rule.id] = _RuleEntry.custom(rule);
    return this;
  }

  ShenShaRegistry replace(ShenShaRule rule) {
    if (!_rules.containsKey(rule.id)) {
      throw ArgumentError('Unknown rule: ${rule.id}');
    }
    _rules[rule.id] = _RuleEntry.custom(rule);
    return this;
  }

  bool remove(String id) => _rules.remove(id) != null;
  void clear() => _rules.clear();

  /// Restore exactly the default 66 rules, discarding custom rules.
  void reset() {
    _rules.clear();
    for (var i = 0; i < 66; i++) {
      final id = 'builtin:$i';
      _rules[id] = _RuleEntry(id, shenShaNameTable[i], i, null);
    }
  }

  ShenShaRuleSet snapshot() => ShenShaRuleSet._(_rules.values);
  BoundShenSha bind(BaziPillarAnalysis chart, {Gender? gender}) =>
      snapshot().bind(chart, gender: gender);
}

class ShenShaRuleSet {
  final List<_RuleEntry> _rules;
  ShenShaRuleSet._(Iterable<_RuleEntry> entries)
    : _rules = List.unmodifiable(entries);
  int get size => _rules.length;
  BoundShenSha bind(BaziPillarAnalysis chart, {Gender? gender}) =>
      BoundShenSha._(this, chart, gender);
  List<ShenShaMatch> evaluate(ShenShaContext context) {
    final p = context.pillars;
    final pillars = FourPillars(
      year: p.year,
      month: p.month,
      day: p.day,
      hour: p.hour,
    );
    for (final value in [...pillars.toJson().values, context.target]) {
      ganzhiIndex(value);
    }
    final frozen = ShenShaContext(
      pillars: pillars,
      target: context.target,
      targetKind: context.targetKind,
      gender: context.gender,
    );
    final bits = _rules.any((r) => r.builtinId != null)
        ? collectTargetShenSha(
            analyzePillars(pillars),
            context.target,
            context.targetKind,
            gender: context.gender,
          )
        : BigInt.zero;
    return List.unmodifiable([
      for (final r in _rules)
        if (r.builtinId == null
            ? r.test!(frozen)
            : hasShenSha(bits, r.builtinId!))
          ShenShaMatch(r.id, r.name, r.builtinId),
    ]);
  }
}

/// Immutable collection and pillar snapshot. Callback closures must remain pure.
class BoundShenSha {
  final ShenShaRuleSet _rules;
  final FourPillars _pillars;
  final Gender? _gender;
  BoundShenSha._(this._rules, BaziPillarAnalysis chart, this._gender)
    : _pillars = FourPillars(
        year: chart.pillars.year,
        month: chart.pillars.month,
        day: chart.pillars.day,
        hour: chart.pillars.hour,
      ) {
    for (final p in _pillars.toJson().values) {
      ganzhiIndex(p);
    }
  }
  List<ShenShaMatch> forTarget(int target, ShenShaTarget targetKind) =>
      _rules.evaluate(
        ShenShaContext(
          pillars: _pillars,
          target: target,
          targetKind: targetKind,
          gender: _gender,
        ),
      );
  Map<String, List<ShenShaMatch>> natal() => Map.unmodifiable({
    'year': forTarget(_pillars.year, ShenShaTarget.year),
    'month': forTarget(_pillars.month, ShenShaTarget.month),
    'day': forTarget(_pillars.day, ShenShaTarget.day),
    'hour': forTarget(_pillars.hour, ShenShaTarget.hour),
  });
}
