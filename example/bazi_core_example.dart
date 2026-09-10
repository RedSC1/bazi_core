import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';

void main() {
  final clock = ZonedTime(
    year: 2000,
    month: 1,
    day: 1,
    hour: 12,
    offsetMinutes: 480,
  );
  final chart = BaziChart.fromZonedTime(
    clock,
    options: BaziOptions(gender: Gender.male),
  );
  print(chart.columns.map((column) => column.name).join(' '));
  print(chart.getQiYun().startCivilTime.toJson());
  for (final decade in chart.getDaYunTable()) {
    print(
      '${ganzhiName(decade.pillar)} ${decade.startVirtualAge}–${decade.endVirtualAge}',
    );
  }
  print(jsonEncode(chart));
}
