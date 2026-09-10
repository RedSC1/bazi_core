import 'dart:convert';
import 'package:bazi_core/bazi_core.dart';

void main() {
  final chart = BaziChart.fromZonedTime(
    ZonedTime(year: 2000, month: 1, day: 1, hour: 12, offsetMinutes: 480),
  );
  final base = BaziShenShaCatalog();
  final catalog = base.addModule(
    BaziShenShaModule('my-school', [
      BaziShenShaRule(
        'day-marker',
        '日柱示例',
        (input) => input.targetKind == ShenShaTarget.day,
      ),
    ]),
  );
  final context = catalog.createContext(
    BaziShenShaSelection(disabledIds: ['builtin:0']),
  );
  final removed = catalog.removeModule('my-school');
  print(
    jsonEncode(context.evaluate(chart, chart.pillars.day, ShenShaTarget.day)),
  );
  if (removed.modules.isNotEmpty) throw StateError('module removal failed');
}
