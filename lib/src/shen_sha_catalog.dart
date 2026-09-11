part of '../bazi_core.dart';

class BaziShenShaInput {
  final BaziPillarAnalysis chart;
  final int target;
  final ShenShaTarget targetKind;
  final Gender? gender;
  const BaziShenShaInput(this.chart, this.target, this.targetKind, this.gender);
}

class BaziShenShaRule {
  final String id, name;

  /// Pure synchronous callback; external captured state is not copied.
  final bool Function(BaziShenShaInput) test;
  const BaziShenShaRule(this.id, this.name, this.test);
}

class BaziShenShaMatch {
  final String id, name;

  /// -1 for custom rules. Built-in names are empty for caller localization.
  final int builtinId;
  const BaziShenShaMatch(this.id, this.name, this.builtinId);
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'builtinId': builtinId,
  };
}

void _catalogKey(String value) {
  if (value.isEmpty || RegExp(r'[:\s]', unicode: true).hasMatch(value)) {
    throw ArgumentError('Keys must be nonempty without whitespace or colon');
  }
}

void _catalogLabel(String value) {
  _catalogKey(value);
  if (value == 'builtin' || value == 'option1') {
    throw ArgumentError('Reserved module label');
  }
}

class BaziShenShaModule {
  final String label;
  final List<BaziShenShaRule> rules;
  BaziShenShaModule(this.label, Iterable<BaziShenShaRule> rules)
    : rules = List.unmodifiable(
        rules.map((r) => BaziShenShaRule(r.id, r.name, r.test)),
      ) {
    _catalogLabel(label);
    if (this.rules.isEmpty) throw ArgumentError('Empty module');
    final seen = <String>{};
    for (final rule in this.rules) {
      _catalogKey(rule.id);
      if (!seen.add(rule.id) || rule.name.trim().isEmpty) {
        throw ArgumentError('Invalid or duplicate rule');
      }
    }
  }
}

class BaziShenShaSelection {
  final List<String> disabledIds;
  BaziShenShaSelection({Iterable<String> disabledIds = const []})
    : disabledIds = List.unmodifiable(disabledIds);
}

class BaziShenShaCatalog {
  final List<BaziShenShaModule> modules;
  BaziShenShaCatalog([Iterable<BaziShenShaModule> modules = const []])
    : modules = List.unmodifiable(
        modules.map((m) => BaziShenShaModule(m.label, m.rules)),
      ) {
    final seen = <String>{};
    for (final m in this.modules) {
      if (!seen.add(m.label)) throw ArgumentError('Duplicate module label');
    }
  }
  BaziShenShaCatalog addModule(BaziShenShaModule module) =>
      BaziShenShaCatalog([...modules, module]);
  BaziShenShaCatalog removeModule(String label) {
    _catalogLabel(label);
    if (!modules.any((m) => m.label == label)) {
      throw ArgumentError('Unknown module');
    }
    return BaziShenShaCatalog(modules.where((m) => m.label != label));
  }

  BaziShenShaContext createContext([BaziShenShaSelection? selection]) =>
      BaziShenShaContext._(this, selection ?? BaziShenShaSelection());
}

class BaziShenShaContext {
  final List<BaziShenShaModule> _modules;
  final Set<String> _disabled;
  BaziShenShaContext._(
    BaziShenShaCatalog catalog,
    BaziShenShaSelection selection,
  ) : _modules = BaziShenShaCatalog(catalog.modules).modules,
      _disabled = Set.unmodifiable(selection.disabledIds) {
    final known = {
      for (var i = 0; i < 66; i++) 'builtin:$i',
      for (final m in _modules)
        for (final r in m.rules) '${m.label}:${r.id}',
    };
    if (_disabled.length != selection.disabledIds.length ||
        !_disabled.every(known.contains)) {
      throw ArgumentError('Unknown or duplicate disabled ID');
    }
  }
  List<BaziShenShaMatch> evaluate(
    BaziPillarAnalysis chart,
    int target,
    ShenShaTarget targetKind, {
    Gender? gender,
  }) {
    final p = chart.pillars;
    for (final v in [p.year, p.month, p.day, p.hour, target]) {
      ganzhiIndex(v);
    }
    final extras = chart.extraPillars;
    final copy = BaziPillarAnalysis._(
      FourPillars(year: p.year, month: p.month, day: p.day, hour: p.hour),
      ExtraPillars(
        extras.mingGong,
        extras.shenGong,
        extras.taiYuan,
        extras.taiXi,
      ),
      chart.dayMaster,
      List.unmodifiable(chart.columns.map(BaziColumn._snapshot)),
    );
    final input = BaziShenShaInput(copy, target, targetKind, gender);
    final bits = collectTargetShenSha(copy, target, targetKind, gender: gender);
    final matches = <BaziShenShaMatch>[];
    for (var i = 0; i < 66; i++) {
      if (!_disabled.contains('builtin:$i') && hasShenSha(bits, i)) {
        matches.add(BaziShenShaMatch('builtin:$i', '', i));
      }
    }
    for (final module in _modules) {
      for (final rule in module.rules) {
        final id = '${module.label}:${rule.id}';
        if (!_disabled.contains(id) && rule.test(input)) {
          matches.add(BaziShenShaMatch(id, rule.name, -1));
        }
      }
    }
    return List.unmodifiable(matches);
  }
}
