import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

void main() {
  final testCases = [
    {
      'name': '2026-03-05 10:04 (今天案例)',
      'y': 2026,
      'm': 3,
      'd': 5,
      'h': 10,
      'i': 4,
    },
    {
      'name': '1990-05-15 14:30 (夏天午后)',
      'y': 1990,
      'm': 5,
      'd': 15,
      'h': 14,
      'i': 30,
    },
    {
      'name': '2000-01-01 00:30 (千禧年子时)',
      'y': 2000,
      'm': 1,
      'd': 1,
      'h': 0,
      'i': 30,
    },
    {
      'name': '1985-11-20 23:30 (晚子时)',
      'y': 1985,
      'm': 11,
      'd': 20,
      'h': 23,
      'i': 30,
    },
    {
      'name': '2024-02-04 17:00 (甲辰立春)',
      'y': 2024,
      'm': 2,
      'd': 4,
      'h': 17,
      'i': 0,
    },
  ];

  for (var tc in testCases) {
    print('--- ${tc['name']} ---');
    final astroTime = AstroDateTime(
      tc['y'] as int,
      tc['m'] as int,
      tc['d'] as int,
      tc['h'] as int,
      tc['i'] as int,
      0,
    );

    final timePack = TimePack.createBySolarTime(clockTime: astroTime);
    final bazi = TimeAdaptor.fromSolar(timePack);
    final lunarDate = LunarDate.fromSolar(astroTime);
    final chart = BaziChart(timePack, bazi, lunarDate, Gender.male);

    print('八字: ${bazi.year} ${bazi.month} ${bazi.day} ${bazi.time}');
    print('命宫: ${chart.mingGong}');
    print('身宫: ${chart.shenGong}');
    print('');
  }
}
