import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  group('子时流派逻辑交叉验证 (J2000 案例)', () {
    // 2000-01-01 23:30:00
    // 该日基础：戊午日 (根据 sxwnl)
    // 次日基础：己未日
    final bt = AstroDateTime(2000, 1, 1, 23, 30, 0);

    test('1. 不分早晚子 (noSplit): 23:00 换日，时柱跟明天', () {
      final chart = BaziChart.createBySolarDate(
        clockTime: bt,
        ratHourMode: RatHourMode.noSplit,
      );
      print('传统派结果: ${chart.bazi.day} ${chart.bazi.time}');
      expect(chart.bazi.day.toString(), '己未');
      expect(chart.bazi.time.toString(), '甲子');
    });

    test('2. 晚子算当天+明天干 (tomorrowGan): 00:00 换日，时柱借明天干', () {
      final chart = BaziChart.createBySolarDate(
        clockTime: bt,
        ratHourMode: RatHourMode.tomorrowGan,
      );
      print('主流派结果: ${chart.bazi.day} ${chart.bazi.time}');
      expect(chart.bazi.day.toString(), '戊午');
      expect(chart.bazi.time.toString(), '甲子');
    });

    test('3. 晚子算当天+今天干 (todayGan): 00:00 换日，时柱用今天干', () {
      final chart = BaziChart.createBySolarDate(
        clockTime: bt,
        ratHourMode: RatHourMode.todayGan,
      );
      print('古法派结果: ${chart.bazi.day} ${chart.bazi.time}');
      expect(chart.bazi.day.toString(), '戊午');
      expect(chart.bazi.time.toString(), '壬子');
    });
  });
}
