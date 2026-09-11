import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

void main() {
  final chart = analyzePillars(
    const FourPillars(year: 0x26, month: 0x62, day: 0x42, hour: 0x35),
  );
  BaziShenShaModule module() => BaziShenShaModule('school', [
    BaziShenShaRule('one', 'First', (_) => true),
    BaziShenShaRule('two', 'Second', (_) => true),
  ]);
  test('default catalog matches every built-in target and gender', () {
    final ctx = BaziShenShaCatalog().createContext();
    for (final gender in [null, Gender.female, Gender.male]) {
      for (final kind in ShenShaTarget.values) {
        for (var p = 0; p < 60; p++) {
          final target = makeGanzhi(p % 10, p % 12),
              ids = shenShaIds(
                collectTargetShenSha(chart, target, kind, gender: gender),
              );
          expect(
            ctx
                .evaluate(chart, target, kind, gender: gender)
                .map((m) => m.toJson()),
            ids.map((id) => {'id': 'builtin:$id', 'name': '', 'builtinId': id}),
          );
        }
      }
    }
  });
  test('module removal is immutable and covers every target', () {
    final base = BaziShenShaCatalog(),
        extended = base.addModule(module()),
        ctx = extended.createContext(),
        removed = extended.removeModule('school');
    expect(base.modules, isEmpty);
    expect(extended.modules.length, 1);
    expect(removed.modules, isEmpty);
    for (final k in ShenShaTarget.values) {
      final defaults = base.createContext().evaluate(
        chart,
        chart.pillars.day,
        k,
      );
      expect(
        ctx.evaluate(chart, chart.pillars.day, k).length,
        defaults.length + 2,
      );
      expect(
        removed
            .createContext()
            .evaluate(chart, chart.pillars.day, k)
            .map((m) => m.toJson()),
        defaults.map((m) => m.toJson()),
      );
    }
    expect(() => extended.modules.clear(), throwsUnsupportedError);
  });
  test('disabled IDs are copied without deleting definitions', () {
    final catalog = BaziShenShaCatalog().addModule(module());
    final ids = [for (var i = 0; i < 66; i++) 'builtin:$i', 'school:one'];
    final ctx = catalog.createContext(BaziShenShaSelection(disabledIds: ids));
    ids.clear();
    final matches = ctx.evaluate(chart, chart.pillars.day, ShenShaTarget.day);
    expect(matches.map((m) => m.toJson()), [
      {'id': 'school:two', 'name': 'Second', 'builtinId': -1},
    ]);
    expect(
      catalog
          .createContext()
          .evaluate(chart, chart.pillars.day, ShenShaTarget.day)
          .length,
      greaterThan(1),
    );
    expect(() => matches.clear(), throwsUnsupportedError);
    expect(() => jsonEncode(matches), returnsNormally);
    expect(
      () => ctx.evaluate(chart, 1, ShenShaTarget.day),
      throwsArgumentError,
    );
  });
  test('complete rule-layer chart is available and immutable', () {
    final rules = [
      BaziShenShaRule('x', 'X', (input) {
        expect(input.chart.extraPillars.toJson(), chart.extraPillars.toJson());
        expect(
          input.chart.columns.map((c) => c.toJson()),
          chart.columns.map((c) => c.toJson()),
        );
        expect(input.chart.dayMaster, chart.dayMaster);
        expect(
          identical(input.chart.columns.first, chart.columns.first),
          isFalse,
        );
        expect(() => input.chart.columns.clear(), throwsUnsupportedError);
        return true;
      }),
    ];
    final m = BaziShenShaModule('school', rules);
    rules.clear();
    expect(
      BaziShenShaCatalog()
          .addModule(m)
          .createContext()
          .evaluate(chart, 0, ShenShaTarget.day)
          .last
          .id,
      'school:x',
    );
  });
  test('reserved keys duplicates and unknown selections reject', () {
    final base = BaziShenShaCatalog(), ext = base.addModule(module());
    for (final name in ['builtin', 'option1', 'a:b', 'a b', '']) {
      expect(
        () => BaziShenShaModule(name, [BaziShenShaRule('x', 'X', (_) => true)]),
        throwsArgumentError,
      );
    }
    expect(() => BaziShenShaModule('x', []), throwsArgumentError);
    expect(
      () => BaziShenShaModule('x', [BaziShenShaRule('a', ' ', (_) => true)]),
      throwsArgumentError,
    );
    expect(
      () => BaziShenShaModule('x', [
        BaziShenShaRule('a', 'A', (_) => true),
        BaziShenShaRule('a', 'B', (_) => true),
      ]),
      throwsArgumentError,
    );
    expect(() => ext.addModule(module()), throwsArgumentError);
    for (final name in ['builtin', 'option1', 'missing']) {
      expect(() => ext.removeModule(name), throwsArgumentError);
    }
    for (final ids in [
      ['builtin:66'],
      ['builtin:0', 'builtin:0'],
      ['missing:x'],
    ]) {
      expect(
        () => base.createContext(BaziShenShaSelection(disabledIds: ids)),
        throwsArgumentError,
      );
    }
  });
  test('exceptions propagate and disabled callbacks are skipped', () {
    final error = StateError('callback');
    final cat = BaziShenShaCatalog().addModule(
      BaziShenShaModule('fail', [
        BaziShenShaRule('x', 'X', (_) => throw error),
      ]),
    );
    expect(
      () => cat.createContext().evaluate(chart, 0, ShenShaTarget.day),
      throwsA(same(error)),
    );
    expect(
      () => cat
          .createContext(BaziShenShaSelection(disabledIds: ['fail:x']))
          .evaluate(chart, 0, ShenShaTarget.day),
      returnsNormally,
    );
  });
  test('public API aliases and object instant inputs', () {
    expect(invalidId, 255);
    expect(TenGodId.biJian, 0);
    expect(LifeStageId.yang, 11);
    expect(PillarSlot.taiXi, 7);
    final v = makeGanzhi(2, 2);
    expect(pillarStem(v), 2);
    expect(pillarBranch(v), 2);
    expect(pillarIndex(v), 2);
    expect(pillarName(v), '丙寅');
    expect(shenShaInfo['stableIdCount'], 66);
    expect(relationKindMaskAll, 0xffff);
    final time = ZonedTime(
      year: 2000,
      month: 1,
      day: 1,
      hour: 12,
      offsetMinutes: 480,
    );
    final a = calculateBazi(time.toJulianTime(), time),
        b = calculateBazi(time.toJulianTime().jdUT1, time);
    expect(a.pillars.toJson(), b.pillars.toJson());
    expect(
      calculateQiYun(time.toJulianTime(), time, a, Gender.male).startJdUT1,
      calculateQiYun(
        time.toJulianTime().jdUT1,
        time,
        a,
        Gender.male,
      ).startJdUT1,
    );
  });
  test('persistent options JSON round trip and clearable settings', () {
    final o = BaziOptions(
      calendarOptions: CalendarOptions(
        mode: CalendarMode.localAstronomical,
        dayBoundaryMode: CalendarDayBoundaryMode.meanSolarMeridian,
        meridianDeg: 75,
        eventAccuracy: Accuracy.accurate,
      ),
      clockMode: BaziClockMode.trueSolar,
      longitudeDeg: 75,
      gender: Gender.male,
    );
    expect(BaziOptions.fromJson(o.toJson()).toJson(), o.toJson());
    final cleared = o.copyWith(
      clearGender: true,
      clearLongitude: true,
      clockMode: BaziClockMode.civil,
    );
    expect(cleared.gender, isNull);
    expect(cleared.longitudeDeg, isNull);
    expect(identical(resolveBaziOptions(o), o), isTrue);
    for (final bad in [
      {'ratHourMode': 'bad'},
      {'utcOffsetMinutes': 1.2},
      {'daYunCount': null},
      {'gender': 3},
      {'eventAccuracy': 'bad'},
    ]) {
      expect(() => BaziOptions.fromJson(bad), throwsArgumentError);
    }
  });
}
