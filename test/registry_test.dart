import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

void main() {
  final chart = analyzePillars(
    const FourPillars(year: 0x26, month: 0x62, day: 0x42, hour: 0x35),
  );
  test('registry defaults equal all built-in target/gender combinations', () {
    final r = ShenShaRegistry();
    expect(r.size, 66);
    for (final gender in [null, Gender.female, Gender.male]) {
      final b = r.bind(chart, gender: gender);
      for (final kind in ShenShaTarget.values) {
        for (var p = 0; p < 60; p++) {
          final pillar = makeGanzhi(p % 10, p % 12),
              ids = shenShaIds(
                collectTargetShenSha(chart, pillar, kind, gender: gender),
              );
          expect(
            b.forTarget(pillar, kind).map((m) => m.toJson()),
            ids.map(
              (id) => {
                'id': 'builtin:$id',
                'name': shenShaNameTable[id],
                'builtinId': id,
              },
            ),
          );
        }
      }
    }
  });
  test('local mutation, stable rule snapshot and JSON-safe matches', () {
    final r = ShenShaRegistry()
      ..register(
        ShenShaRule(
          id: 'example:day',
          name: '日柱示例',
          test: (c) => c.targetKind == ShenShaTarget.day,
        ),
      );
    final b = r.bind(chart);
    expect(b.natal()['day']!.last.name, '日柱示例');
    expect(b.natal()['hour']!.any((m) => m.id == 'example:day'), isFalse);
    r.replace(ShenShaRule(id: 'example:day', name: '替换', test: (_) => false));
    expect(
      r.bind(chart).natal()['day']!.any((m) => m.id == 'example:day'),
      isFalse,
    );
    r.replace(ShenShaRule(id: 'builtin:0', name: '自定天乙', test: (_) => true));
    expect(r.bind(chart).natal()['hour']!.first.toJson(), {
      'id': 'builtin:0',
      'name': '自定天乙',
    });
    expect(r.remove('builtin:0'), isTrue);
    expect(r.remove('builtin:0'), isFalse);
    r.clear();
    expect(r.bind(chart).natal()['day'], isEmpty);
    expect(b.natal()['day']!.last.name, '日柱示例');
    r.reset();
    expect(r.size, 66);
    expect(ShenShaRegistry().size, 66);
    expect(() => jsonEncode(b.natal()), returnsNormally);
    expect(() => b.natal()['day']!.clear(), throwsUnsupportedError);
  });
  test('registry rejects invalid keys and targets', () {
    final r = ShenShaRegistry(includeBuiltins: false);
    expect(
      () => ShenShaRule(id: '', name: 'x', test: (_) => true),
      throwsArgumentError,
    );
    expect(
      () => r.register(
        ShenShaRule(id: 'builtin:66', name: 'x', test: (_) => true),
      ),
      throwsArgumentError,
    );
    expect(
      () => r.replace(ShenShaRule(id: 'x', name: 'x', test: (_) => true)),
      throwsArgumentError,
    );
    r.register(ShenShaRule(id: 'x', name: 'x', test: (_) => true));
    expect(
      () => r.register(ShenShaRule(id: 'x', name: 'x', test: (_) => true)),
      throwsArgumentError,
    );
    expect(
      () => r.bind(chart).forTarget(1, ShenShaTarget.day),
      throwsArgumentError,
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
