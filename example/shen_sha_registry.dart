import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';

void main() {
  final chart = BaziChart.fromZonedTime(
    ZonedTime(year: 2000, month: 1, day: 1, hour: 12, offsetMinutes: 480),
    options: BaziOptions(gender: Gender.male),
  );
  final registry = ShenShaRegistry()
    ..register(
      ShenShaRule(
        id: 'example:day-marker',
        name: '日柱示例',
        test: (c) => c.targetKind == ShenShaTarget.day,
      ),
    );
  final bound = registry.bind(chart, gender: chart.options.gender);
  registry.remove('example:day-marker');
  print(jsonEncode(bound.natal()));
  print(
    jsonEncode(
      bound.forTarget(chart.extraPillars.mingGong, ShenShaTarget.mingGong),
    ),
  );
}
