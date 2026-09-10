import 'dart:convert';
import 'dart:io';
import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

void main() {
  final data = jsonDecode(
    File('test/fixtures/js-parity.json').readAsStringSync(),
  );
  test(
    '90 JS charts: three solar clocks, Zi modes, historical dates and fortune',
    () {
      for (final row in data['charts']) {
        final t = row['input'], o = row['options'];
        final time = ZonedTime(
          year: t['year'],
          month: t['month'],
          day: t['day'],
          hour: t['hour'],
          minute: t['minute'],
          second: (t['second'] as num).toDouble(),
          offsetMinutes: t['offsetMinutes'],
        );
        final options = BaziOptions(
          clockMode:
              BaziClockMode.values[[
                'civil',
                'mean-solar',
                'true-solar',
              ].indexOf(o['clockMode'])],
          ratHourMode:
              RatHourMode.values[[
                'next-day',
                'current-day',
                'current-day-tomorrow-stem',
              ].indexOf(o['ratHourMode'])],
          longitudeDeg: 75,
          gender: Gender.values[o['gender']],
          qiYunTimeModel: QiYunTimeModel.values[o['qiYunTimeModel']],
          daYunBoundaryModel:
              DaYunBoundaryModel.values[o['daYunBoundaryModel']],
        );
        final c = BaziChart.fromZonedTime(time, options: options);
        expect(c.pillars.toJson(), row['pillars'], reason: '$t $o');
        final v = c.birthCivilTime.toJson();
        for (final key in ['year', 'month', 'day', 'hour', 'minute']) {
          expect(v[key], row['virtualTime'][key], reason: 'clock $t $o $key');
        }
        expect(
          (c.birthCivilTime.second - row['virtualTime']['second']).abs(),
          lessThan(0.001),
        );
        final q = c.getQiYun(), expected = row['qiYun'];
        expect(q.direction, expected['direction']);
        expect(
          (q.jieIntervalDays - expected['interval']).abs() * 86400,
          lessThan(0.01),
        );
        // Traditional scaling magnifies event-root roundoff by about 120.
        expect((q.startJdUT1 - expected['start']).abs() * 86400, lessThan(1.3));
        final ds = c.getDaYunTable();
        for (var i = 0; i < ds.length; i++) {
          final d = ds[i], e = row['decades'][i];
          expect([
            d.pillar,
            d.startVirtualAge,
            d.endVirtualAge,
          ], e.sublist(0, 3));
          expect((d.startJdUT1 - e[3]).abs() * 86400, lessThan(1.3));
          expect((d.endJdUT1 - e[4]).abs() * 86400, lessThan(1.3));
        }
      }
    },
  );
  test('56160 arbitrary target Shen-Sha comparisons with JS', () {
    var count = 0;
    for (final row in data['arbitrary']) {
      final p = row['pillars'],
          c = analyzePillars(
            FourPillars(
              year: p['year'],
              month: p['month'],
              day: p['day'],
              hour: p['hour'],
            ),
          );
      final gender = row['gender'] == null
          ? null
          : Gender.values[row['gender']];
      var index = 0;
      for (final kind in ShenShaTarget.values) {
        for (var i = 0; i < 60; i++) {
          expect(
            collectTargetShenSha(
              c,
              makeGanzhi(i % 10, i % 12),
              kind,
              gender: gender,
            ).toString(),
            row['words'][index++],
            reason: '$p $gender $kind $i',
          );
          count++;
        }
      }
    }
    expect(count, 56160);
  });
}
