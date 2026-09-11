import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';
import 'package:test/test.dart';

void main() {
  test('legacy J2000 Zi-hour conventions, noSplit means nextDay', () {
    final t = ZonedTime(
      year: 2000,
      month: 1,
      day: 1,
      hour: 23,
      minute: 30,
      offsetMinutes: 480,
    );
    for (final (mode, day, hour) in [
      (RatHourMode.nextDay, '己未', '甲子'),
      (RatHourMode.currentDayTomorrowStem, '戊午', '甲子'),
      (RatHourMode.currentDay, '戊午', '壬子'),
    ]) {
      final c = BaziChart.fromZonedTime(
        t,
        options: BaziOptions(ratHourMode: mode),
      );
      expect(ganzhiName(c.pillars.day), day);
      expect(ganzhiName(c.pillars.hour), hour);
    }
  });
  test('legacy Tai-Xi 甲子 and 丙寅', () {
    expect(calculateExtraPillars(0, 0, 0, 0).taiXi, makeGanzhi(5, 1));
    expect(
      calculateExtraPillars(0, 0, makeGanzhi(2, 2), 0).taiXi,
      makeGanzhi(7, 11),
    );
  });
  test('all sexagenary pillars encode and decode', () {
    for (var i = 0; i < 60; i++) {
      final p = packPillar(i % 10, i % 12);
      expect(unpackPillar(p).index, i);
    }
    expect(() => packPillar(0, 1), throwsArgumentError);
  });
  test(
    'source clock, calculation clock and gender remain distinct in JSON',
    () {
      final time = ZonedTime(
        year: 2000,
        month: 1,
        day: 1,
        hour: 0,
        minute: 5,
        second: 12.5,
        offsetMinutes: 345,
      );
      for (final mode in BaziClockMode.values) {
        final c = BaziChart.fromZonedTime(
          time,
          options: BaziOptions(
            gender: Gender.female,
            clockMode: mode,
            longitudeDeg: 75,
          ),
        );
        final j = jsonDecode(jsonEncode(c));
        expect(j['birth']['clockTime'], time.toJson());
        expect(j['birth']['chartTime'], c.birthChartTime.toJson());
        expect(j['birth']['virtualTime'], c.birthChartTime.toJson());
        expect(c.birthCivilTime.toJson(), c.birthChartTime.toJson());
        expect(j['options']['utcOffsetMinutes'], 480);
        expect(j['birth']['gender'], 'female');
        if (mode != BaziClockMode.civil) {
          expect(c.birthChartTime.day, isNot(time.day));
        }
      }
      final c = BaziChart.fromInstant(time.toJulianTime().jdUT1, time);
      expect(c.toJson()['fortune'], isNull);
      expect(c.birthClockTime, isNull);
      expect(() => c.getQiYun(), throwsStateError);
    },
  );
  test('solar and lunar day constructors require an explicit birth hour', () {
    final options = BaziOptions(
      calendarOptions: CalendarOptions(utcOffsetMinutes: 480),
    );
    final solar = BaziChart.fromSolarDay(
      const CalendarDate(year: 2003, month: 3, day: 13),
      hour: 9,
      minute: 30,
      options: options,
    );
    final lunar = BaziChart.fromLunarDay(
      const LunarDate(year: 2003, month: 2, day: 11),
      hour: 9,
      minute: 30,
      options: options,
    );
    expect(lunar.pillars.toJson(), solar.pillars.toJson());
    expect(lunar.options, same(options));
  });
  test('66-bit Shen-Sha representation is lossless', () {
    final bits = (BigInt.one << 65) | (BigInt.one << 64) | BigInt.one;
    expect(shenShaIds(bits), [0, 64, 65]);
    expect(shenShaWords(bits), (BigInt.one, BigInt.from(3)));
    expect(() => hasShenSha(bits, 66), throwsRangeError);
  });
  test('invalid options and impossible clocks fail early', () {
    expect(
      () => BaziOptions(clockMode: BaziClockMode.trueSolar),
      throwsArgumentError,
    );
    expect(() => BaziOptions(longitudeDeg: double.nan), throwsRangeError);
    expect(
      () =>
          BaziOptions(calendarOptions: CalendarOptions(utcOffsetMinutes: 1.5)),
      throwsArgumentError,
    );
    expect(() => BaziOptions(daYunCount: -1), throwsRangeError);
    final c = analyzePillars(
      const FourPillars(year: 0, month: 0, day: 0, hour: 0),
    );
    expect(() => generateXiaoYun(c, 0, 0), throwsRangeError);
    expect(() => generateXiaoYun(c, 1, 0, startAge: 0), throwsRangeError);
    expect(
      () => calculateQiYun(
        2451545,
        const CalendarDate(year: 1582, month: 10, day: 10),
        c,
        Gender.male,
      ),
      throwsArgumentError,
    );
    expect(() => c.columns.clear(), throwsUnsupportedError);
    expect(() => getHiddenStems(1).clear(), throwsUnsupportedError);
  });
}
