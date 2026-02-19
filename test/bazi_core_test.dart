import 'package:bazi_core/bazi_core.dart';
import 'package:bazi_core/src/astronomy/fortune.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  test('BaziChart and Fortune calculation', () {
    final bt = AstroDateTime(2026, 2, 19, 20, 28, 0);
    final chart = BaziChart.createBySolarDate(
      clockTime: bt,
      gender: Gender.male,
    );

    final fortune = Fortune.createByBaziChart(chart);

    print('八字: ${chart.bazi}');
    print('农历: ${chart.lunarDate}');
    print('');
    print('起运时间: ${fortune.qiYunTime}');
    print('起运详情: ${fortune.qiYunDt}');
    print('起运年龄: ${fortune.startAge.toStringAsFixed(1)} 岁');
    print('大运方向: ${fortune.direction == 1 ? "顺行" : "逆行"}');
    print('');
    print('=== 前8步大运 ===');

    for (int i = 1; i <= 8; i++) {
      final decade = fortune.getDecadeByIndex(i);
      print(
        '第${decade.index}步: ${decade.ganZhi} | '
        '${decade.startAge}-${decade.endAge}岁 | '
        '${decade.startTime} - ${decade.endTime}',
      );
    }

    // Add basic assertions to verify the test runs correctly
    expect(chart.bazi, isNotNull);
    expect(fortune, isNotNull);
  });
}
