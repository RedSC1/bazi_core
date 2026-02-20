import 'package:bazi_core/bazi_core.dart';
import 'package:bazi_core/src/astronomy/fortune.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:test/test.dart';

void main() {
  test('BaziChart and Fortune calculation', () {
    final bt = AstroDateTime(2026, 2, 19, 23, 28, 0);
    final chart = BaziChart.createBySolarDate(
      clockTime: bt,
      gender: Gender.male,
      splitByRatHour: false,
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

    expect(chart.bazi, isNotNull);
    expect(fortune, isNotNull);
  });

  test('GanZhi getKongWang', () {
    final gz1 = GanZhi(TianGan.jia, DiZhi.zi);
    expect(gz1.getKongWang(), equals([DiZhi.xu, DiZhi.hai]));

    final gz2 = GanZhi(TianGan.jia, DiZhi.xu);
    expect(gz2.getKongWang(), equals([DiZhi.shen, DiZhi.you]));

    final gz3 = GanZhi(TianGan.jia, DiZhi.shen);
    expect(gz3.getKongWang(), equals([DiZhi.wu, DiZhi.wei]));

    final gz4 = GanZhi(TianGan.yi, DiZhi.chou);
    expect(gz4.getKongWang(), equals([DiZhi.hai, DiZhi.xu]));
  });
}
