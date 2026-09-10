import 'dart:convert';
import 'dart:io';
import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

List<dynamic> rows(String name) =>
    (jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
            as Map)['rows']
        as List;
void main() {
  test('3848 exhaustive primitive cases from the shared C++ fixture', () {
    final cases = rows('primitives-cpp');
    expect(cases.length, 3848);
    for (final row in cases) {
      final a = (row[1] as List).cast<int>();
      List<int> r(RelationFlags v) => [v.flags, v.combinedElement ?? 255];
      final Object actual = switch (row[0]) {
        'tenGod' => getTenGod(a[0], a[1]),
        'hiddenStems' => getHiddenStems(a[0]),
        'kongWang' => getKongWang(a[0]),
        'lifeStage' => getLifeStage(a[0], a[1], EarthPalaceMode.values[a[2]]),
        'stemRelation' => r(calculateStemRelation(a[0], a[1])),
        'branchRelation' => r(calculateBranchRelation(a[0], a[1])),
        'tripleRelation' => r(calculateBranchTripleRelation(a[0], a[1], a[2])),
        'flowMonth' => calculateFlowMonth(a[0], a[1]),
        'flowHour' => calculateFlowHour(a[0], a[1]),
        'siling' =>
          getRenyuanSilingSegments(a[0], RenyuanSilingTable.values[a[1]])
              .map(
                (s) => [s.stem, s.origin.index, s.index, s.startDay, s.endDay],
              )
              .toList(),
        _ => throw StateError('Unknown primitive ${row[0]}'),
      };
      expect(actual, row[2], reason: '${row[0]} $a');
    }
  });
  test(
    '1024 seeded C++ charts: extras, columns, relations and all gender variants',
    () {
      final cases = rows('charts-cpp');
      expect(cases.length, 1024);
      for (var i = 0; i < cases.length; i++) {
        final row = cases[i], p = (row['pillars'] as List).cast<int>();
        final c = analyzePillars(
          FourPillars(year: p[0], month: p[1], day: p[2], hour: p[3]),
          earthPalaceMode: EarthPalaceMode.values[row['mode']],
        );
        final sha = [
          for (var k = 0; k < 4; k++)
            for (final gender in [null, Gender.female, Gender.male])
              (() {
                final (lo, hi) = shenShaWords(
                  collectTargetShenSha(
                    c,
                    p[k],
                    ShenShaTarget.values[k],
                    gender: gender,
                  ),
                );
                return [lo.toString(), hi.toString()];
              })(),
        ];
        expect(
          [
            ...c.extraPillars.toJson().values,
            ...c.columns.map(
              (p) => [
                p.visibleTenGod,
                p.lifeStage,
                p.nayinId,
                p.hiddenStems,
                p.hiddenTenGods,
              ],
            ),
            collectChartRelations(c)
                .map(
                  (r) => [r.kind.index, r.pillarMask, r.combinedElement ?? 255],
                )
                .toList(),
            sha,
          ],
          row['expected'],
          reason: 'chart $i',
        );
      }
    },
  );
  test('144 C++ fortune cases, all 3 x 3 model combinations', () {
    final cases = rows('fortune-cpp');
    expect(cases.length, 144);
    void near(num a, num b, double seconds) =>
        expect((a - b).abs() * 86400, lessThanOrEqualTo(seconds));
    for (final row in cases) {
      final a = (row['input'] as List).cast<int>(), e = row['expected'] as List;
      final birth = ZonedTime(
        year: a[0],
        month: a[1],
        day: 19,
        hour: a[2] == 1 ? 23 : 0,
        minute: 28,
        offsetMinutes: 480,
      );
      final c = BaziChart.fromZonedTime(birth);
      expect(c.pillars.toJson().values, e[0]);
      final q = calculateQiYun(
        birth.toJulianTime().jdUT1,
        birth,
        c,
        Gender.values[a[2]],
        timeModel: QiYunTimeModel.values[a[3]],
      );
      final et = a[0] >= 2027 ? 150.0 : 1.0,
          ft = a[0] >= 2027 ? 20000.0 : 125.0;
      expect(q.direction, e[1][0]);
      expect(q.referenceJie.indexFromWinterSolstice, e[1][1]);
      near(q.jieIntervalDays, e[1][2], et);
      near(q.startAgeYears * 3, e[1][3] * 3, et);
      near(q.referenceJie.time.jdUT1, e[1][4], et);
      near(q.startJdUT1, e[1][5], ft);
      final decades = generateDaYun(
        birth,
        c,
        q,
        boundaryModel: DaYunBoundaryModel.values[a[4]],
      );
      for (var i = 0; i < decades.length; i++) {
        final d = decades[i];
        expect(d.pillar, e[2][i][0]);
        if (a[0] < 2027) {
          expect([
            d.startVirtualAge,
            d.endVirtualAge,
          ], (e[2][i] as List).sublist(1, 3));
        }
        near(d.startJdUT1, e[2][i][3], ft);
        near(d.endJdUT1, e[2][i][4], ft);
      }
    }
  });
}
