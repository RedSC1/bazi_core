import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

ZonedTime clock(int y, int m, int d, [int h = 0, int minute = 0]) => ZonedTime(
  year: y,
  month: m,
  day: d,
  hour: h,
  minute: minute,
  offsetMinutes: 480,
);
CalendarDate date(int y, int m, int d) =>
    CalendarDate(year: y, month: m, day: d);
List<BaziDateCandidate> onDate(int y, int m, int d, {BaziOptions? options}) =>
    searchBaziDates(
      BaziDateSearchQuery(
        startDate: date(y, m, d),
        endDate: date(y, m, d),
        options: options,
      ),
    );
void main() {
  test('normal date and full chart round trip', () {
    final source = clock(2026, 2, 19, 10, 30),
        c = BaziChart.fromZonedTime(source);
    final dates = searchBaziDates(
      BaziDateSearchQuery(
        year: c.pillars.year,
        month: c.pillars.month,
        day: c.pillars.day,
        startDate: date(2026, 2, 19),
        endDate: date(2026, 2, 19),
      ),
    );
    expect(dates.length, 1);
    expect(dates.single.phase, BaziDatePhase.normal);
    final full = reverseLookupBazi(
      year: c.pillars.year,
      month: c.pillars.month,
      day: c.pillars.day,
      hour: c.pillars.hour,
      startDate: date(2026, 2, 19),
      endDate: date(2026, 2, 19),
    );
    expect(full.length, 1);
    expect(full.single.chart.pillars.toJson(), c.pillars.toJson());
    expect(
      full.single.timeCandidate!.startTime.toJulianTime().jdUT1,
      lessThanOrEqualTo(source.toJulianTime().jdUT1),
    );
    expect(
      full.single.timeCandidate!.endTime.toJulianTime().jdUT1,
      greaterThanOrEqualTo(source.toJulianTime().jdUT1),
    );
  });
  test('Li-Chun date is split', () {
    final r = onDate(2026, 2, 4);
    expect(r.map((c) => c.phase), [
      BaziDatePhase.beforeJie,
      BaziDatePhase.afterJie,
    ]);
    expect(r.map((c) => c.jieName), ['立春', '立春']);
    expect(r.first.chart.pillars.year, isNot(r.last.chart.pillars.year));
  });
  test('historical assigned date and astronomical override', () {
    expect(onDate(500, 2, 2).map((c) => c.phase), [BaziDatePhase.normal]);
    expect(onDate(500, 2, 3).map((c) => c.phase), [BaziDatePhase.afterJie]);
    expect(
      onDate(
        500,
        2,
        2,
        options: BaziOptions(pillarHistoricalMode: PillarHistoricalMode.off),
      ).map((c) => c.phase),
      [BaziDatePhase.beforeJie, BaziDatePhase.afterJie],
    );
  });
  test('invalid dates and Wu-Hu-Dun pair rejected', () {
    expect(() => onDate(2026, 2, 30), throwsArgumentError);
    expect(
      () => searchBaziDates(
        BaziDateSearchQuery(
          year: 0,
          month: makeGanzhi(0, 2),
          startDate: date(1984, 1, 1),
          endDate: date(1984, 12, 31),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => searchBaziDates(
        BaziDateSearchQuery(
          startDate: date(2026, 2, 2),
          endDate: date(2026, 2, 1),
        ),
      ),
      throwsRangeError,
    );
  });
  test('Zi month spans civil year and day-only search advances 60 days', () {
    final c = BaziChart.fromZonedTime(clock(2025, 12, 20, 12));
    final r = searchBaziDates(
      BaziDateSearchQuery(
        year: c.pillars.year,
        month: c.pillars.month,
        day: c.pillars.day,
        startDate: date(2025, 1, 1),
        endDate: date(2026, 2, 28),
      ),
    );
    expect(r.length, 1);
    expect(
      [r.single.date.year, r.single.date.month, r.single.date.day],
      [2025, 12, 20],
    );
    final day = BaziChart.fromZonedTime(clock(2026, 1, 1, 12)).pillars.day;
    final days = searchBaziDates(
      BaziDateSearchQuery(
        day: day,
        startDate: date(2026, 1, 1),
        endDate: date(2026, 7, 31),
      ),
    );
    expect(days.length, greaterThanOrEqualTo(4));
    for (var i = 1; i < days.length; i++) {
      expect(
        (days[i].sampleTime.toJulianTime().jdUT1 -
                days[i - 1].sampleTime.toJulianTime().jdUT1)
            .round(),
        60,
      );
    }
  });
  test('all Zi-hour modes split time ranges correctly', () {
    for (final mode in RatHourMode.values) {
      final d = onDate(
        2026,
        2,
        19,
        options: BaziOptions(ratHourMode: mode),
      ).single;
      final ranges = searchBaziTimesForDate(d);
      expect(ranges.length, mode == RatHourMode.nextDay ? 12 : 13);
      expect(
        ranges.where((c) => c.isLateZi).length,
        mode == RatHourMode.nextDay ? 0 : 1,
      );
      for (final r in ranges) {
        expect(r.chart.pillars.day, d.chart.pillars.day);
        expect(
          r.startTime.toJulianTime().jdUT1,
          lessThanOrEqualTo(r.endTime.toJulianTime().jdUT1),
        );
      }
    }
  });
  test('full reverse retains Li-Chun late-Zi stem conventions', () {
    for (final (mode, stem) in [
      (RatHourMode.currentDay, 0),
      (RatHourMode.currentDayTomorrowStem, 2),
    ]) {
      final r = reverseLookupBazi(
        year: makeGanzhi(2, 6),
        month: makeGanzhi(6, 2),
        day: makeGanzhi(5, 9),
        hour: makeGanzhi(stem, 0),
        startDate: date(2026, 2, 4),
        endDate: date(2026, 2, 4),
        options: BaziOptions(ratHourMode: mode),
      );
      expect(r.length, 1);
      expect(r.single.dateCandidate.phase, BaziDatePhase.afterJie);
      expect(r.single.timeCandidate!.label, '晚子时');
    }
  });
}
