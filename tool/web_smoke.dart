import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';

void check(bool value, String label) {
  if (!value) throw StateError(label);
}

void main() {
  final high = (BigInt.one << 65) | BigInt.one;
  check(shenShaIds(high).join(',') == '0,65', '66-bit BigInt');
  check(shenShaWords(high).$2 == BigInt.two, 'high uint64 word');
  final chart = BaziChart.fromZonedTime(
    ZonedTime(
      year: 2000,
      month: 1,
      day: 1,
      hour: 23,
      minute: 30,
      offsetMinutes: 480,
    ),
    options: BaziOptions(gender: Gender.male),
  );
  check(ganzhiName(chart.pillars.day) == '己未', 'Zi day');
  check(ganzhiName(chart.pillars.hour) == '甲子', 'Zi hour');
  check(chart.getDaYunTable().length == 8, 'decades');
  check(
    (jsonDecode(jsonEncode(chart)) as Map)['schemaVersion'] == 'bazi-chart-v1',
    'JSON',
  );
  final dates = searchBaziDates(
    BaziDateSearchQuery(
      startDate: const CalendarDate(year: 2026, month: 2, day: 19),
      endDate: const CalendarDate(year: 2026, month: 2, day: 19),
    ),
  );
  check(searchBaziTimesForDate(dates.single).length == 12, 'reverse lookup');
  print('Dart/JS smoke passed');
}
